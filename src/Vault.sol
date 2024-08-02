// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {AccessControlUpgradeable as AccessControl} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {ITCAPV2, IERC20} from "./interface/ITCAPV2.sol";
import {IVault, IVersioned} from "./interface/IVault.sol";
import {IPocket} from "./interface/pockets/IPocket.sol";
import {FeeCalculatorLib} from "./lib/FeeCalculatorLib.sol";
import {IPermit2, ISignatureTransfer} from "permit2/src/interfaces/IPermit2.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

/// @title Vault
/// @notice Vaults manage deposits of collateral and mint TCAP tokens
contract Vault is IVault, AccessControl {
    using FeeCalculatorLib for MintData;
    using SafeCast for uint256;

    struct Deposit {
        address user;
        uint88 pocketId;
        bool enabled;
        uint256 mintAmount;
        uint256 feeIndex;
        uint256 accruedInterest;
    }

    struct Pocket {
        IPocket pocket;
        bool enabled;
    }

    struct FeeData {
        uint256 index;
        uint16 fee;
        uint40 lastUpdated;
    }

    struct MintData {
        mapping(uint256 mintId => Deposit deposit) deposits;
        FeeData feeData;
    }

    /// @custom:storage-location erc7201:tcapv2.storage.vault
    struct VaultStorage {
        mapping(uint88 pocketId => Pocket pocket) pockets;
        uint88 pocketCounter;
        uint256 depositCounter;
        MintData mintData;
    }

    // keccak256(abi.encode(uint256(keccak256("tcapv2.storage.vault")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant VaultStorageLocation = 0xead32f79207e43129359e4c6890b619e37e73a4cc1d61050c081a5aea1b4df00;

    bytes32 public constant FEE_SETTER_ROLE = keccak256("FEE_SETTER_ROLE");
    bytes32 public constant ORACLE_SETTER_ROLE = keccak256("ORACLE_SETTER_ROLE");

    ITCAPV2 public immutable TCAPV2;
    IERC20 public immutable COLLATERAL;
    IPermit2 private immutable PERMIT2;

    /// @dev ensures loan is healthy after any action is performed
    modifier ensureLoanHealthy() {
        _;
        // todo: ensure that loan is healthy
    }

    constructor(ITCAPV2 tCAPV2_, IERC20 collateral_, IPermit2 permit2_) {
        TCAPV2 = tCAPV2_;
        COLLATERAL = collateral_;
        PERMIT2 = permit2_;
        _disableInitializers();
    }

    function initialize(address admin, uint16 initialFee) public initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _updateInterestRate(initialFee);
    }

    function _getVaultStorage() private pure returns (VaultStorage storage $) {
        assembly {
            $.slot := VaultStorageLocation
        }
    }

    /// @inheritdoc IVault
    function addPocket(IPocket pocket) external onlyRole(DEFAULT_ADMIN_ROLE) returns (uint88 pocketId) {
        if (address(pocket) == address(0) || address(pocket.VAULT()) != address(this)) revert InvalidValue();
        VaultStorage storage $ = _getVaultStorage();
        pocketId = $.pocketCounter++;
        $.pockets[pocketId] = Pocket({pocket: pocket, enabled: true});
        emit PocketAdded(pocketId, pocket);
    }

    /// @inheritdoc IVault
    function removePocket(uint88 pocketId) external onlyRole(DEFAULT_ADMIN_ROLE) {
        VaultStorage storage $ = _getVaultStorage();
        if (!$.pockets[pocketId].enabled) revert PocketNotEnabled(pocketId);
        $.pockets[pocketId].enabled = false;
        emit PocketDisabled(pocketId);
    }

    /// @inheritdoc IVault
    function updateInterestRate(uint16 fee) external onlyRole(FEE_SETTER_ROLE) {
        _updateInterestRate(fee);
    }

    /// @inheritdoc IVault
    function deposit(uint88 pocketId, uint256 amount) external returns (uint256 shares) {
        IPocket pocket = _getPocket(pocketId);
        COLLATERAL.transferFrom(msg.sender, address(pocket), amount);
        shares = pocket.registerDeposit(msg.sender, amount);
        emit Deposited(msg.sender, pocketId, amount, shares);
    }

    /// @inheritdoc IVault
    function depositWithPermit(uint88 pocketId, uint256 amount, IPermit2.PermitTransferFrom memory permit, bytes calldata signature)
        external
        returns (uint256 shares)
    {
        if (permit.permitted.token != address(COLLATERAL)) revert InvalidToken();
        IPocket pocket = _getPocket(pocketId);
        IPermit2.SignatureTransferDetails memory transferDetails = ISignatureTransfer.SignatureTransferDetails({to: address(pocket), requestedAmount: amount});
        PERMIT2.permitTransferFrom(permit, transferDetails, msg.sender, signature);
        shares = pocket.registerDeposit(msg.sender, amount);
        emit Deposited(msg.sender, pocketId, amount, shares);
    }

    function withdraw(uint88 pocketId, uint256 shares, address to) external ensureLoanHealthy returns (uint256 amount) {
        // TODO: before withdrawing calculate interest and withdraw it from the pocket
        // probably also add ability to specify underlying token amount instead of shares when withdrawing and or
        // allow passing type(uint256).max to withdraw all tokens
        IPocket pocket = _getPocket(pocketId);
        amount = pocket.withdraw(msg.sender, shares, to);
        emit Withdrawn(msg.sender, pocketId, to, shares, amount);
    }

    function mint(uint88 pocketId, uint256 amount) external ensureLoanHealthy {
        MintData storage $ = _getVaultStorage().mintData;
        $.modifyPosition(_toMintId(msg.sender, pocketId), amount.toInt256());
        TCAPV2.mint(msg.sender, amount);
    }

    function burn(uint88 pocketId, uint256 amount) external {
        MintData storage $ = _getVaultStorage().mintData;
        $.modifyPosition(_toMintId(msg.sender, pocketId), -amount.toInt256());
        TCAPV2.burn(msg.sender, amount);
    }

    // TODO: liquidation

    function collateralOf(address user, uint88 pocketId) external view returns (uint256) {
        // TODO: calculate interest and subtract from the pocket balance
        return _getPocket(pocketId).balanceOf(user);
    }

    function mintedAmount(address user, uint88 pocketId) external view returns (uint256) {
        return _getVaultStorage().mintData.deposits[_toMintId(user, pocketId)].mintAmount;
    }

    function _updateInterestRate(uint16 fee) internal {
        VaultStorage storage $ = _getVaultStorage();
        $.mintData.setInterestRate(fee);
        emit InterestRateUpdated(fee);
    }

    function _getPocket(uint88 pocketId) internal view returns (IPocket) {
        Pocket storage p = _getVaultStorage().pockets[pocketId];
        if (!p.enabled) revert PocketNotEnabled(pocketId);
        return p.pocket;
    }

    function _toMintId(address user, uint88 pocketId) internal pure returns (uint256) {
        return uint256(keccak256(abi.encode(user, pocketId)));
    }

    /// @inheritdoc IVersioned
    function version() public pure returns (string memory) {
        return "1.0.0";
    }
}
