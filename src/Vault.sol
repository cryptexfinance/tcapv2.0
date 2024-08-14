// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {AccessControlUpgradeable as AccessControl} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {Multicall} from "./lib/Multicall.sol";
import {ITCAPV2, IERC20} from "./interface/ITCAPV2.sol";
import {IVault, IVersioned} from "./interface/IVault.sol";
import {IPocket} from "./interface/pockets/IPocket.sol";
import {FeeCalculatorLib} from "./lib/FeeCalculatorLib.sol";
import {IPermit2, ISignatureTransfer} from "permit2/src/interfaces/IPermit2.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {IOracle} from "./interface/IOracle.sol";
import {Constants} from "./lib/Constants.sol";

/// @title Vault
/// @notice Vaults manage deposits of collateral and mint TCAP tokens
contract Vault is IVault, AccessControl, Multicall {
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
        IOracle oracle;
        address feeRecipient;
        uint96 liquidationThreshold;
        MintData mintData;
    }

    // keccak256(abi.encode(uint256(keccak256("tcapv2.storage.vault")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant VaultStorageLocation = 0xead32f79207e43129359e4c6890b619e37e73a4cc1d61050c081a5aea1b4df00;

    bytes32 public constant POCKET_SETTER_ROLE = keccak256("POCKET_SETTER_ROLE");
    bytes32 public constant FEE_SETTER_ROLE = keccak256("FEE_SETTER_ROLE");
    bytes32 public constant ORACLE_SETTER_ROLE = keccak256("ORACLE_SETTER_ROLE");
    bytes32 public constant LIQUIDATION_SETTER_ROLE = keccak256("LIQUIDATION_SETTER_ROLE");

    ITCAPV2 public immutable TCAPV2;
    IERC20 public immutable COLLATERAL;
    IPermit2 private immutable PERMIT2;

    /// @dev ensures loan is healthy after any action is performed
    modifier ensureLoanHealthy(address user, uint88 pocketId) {
        _;
        if (healthFactor(user, pocketId) < liquidationThreshold()) revert LoanNotHealthy();
    }

    constructor(ITCAPV2 tCAPV2_, IERC20 collateral_, IPermit2 permit2_) {
        TCAPV2 = tCAPV2_;
        COLLATERAL = collateral_;
        PERMIT2 = permit2_;
        _disableInitializers();
    }

    function initialize(address admin, uint16 initialFee, address oracle_, address feeRecipient_, uint96 liquidationThreshold_) public initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _updateInterestRate(initialFee);
        _updateOracle(oracle_);
        _updateFeeRecipient(feeRecipient_);
        _updateLiquidationThreshold(liquidationThreshold_);
    }

    function _getVaultStorage() private pure returns (VaultStorage storage $) {
        assembly {
            $.slot := VaultStorageLocation
        }
    }

    /// @inheritdoc IVault
    function addPocket(IPocket pocket) external onlyRole(POCKET_SETTER_ROLE) returns (uint88 pocketId) {
        if (address(pocket) == address(0) || address(pocket.VAULT()) != address(this) || pocket.UNDERLYING_TOKEN() != COLLATERAL) revert InvalidValue();
        VaultStorage storage $ = _getVaultStorage();
        pocketId = ++$.pocketCounter;
        $.pockets[pocketId] = Pocket({pocket: pocket, enabled: true});
        emit PocketAdded(pocketId, pocket);
    }

    /// @inheritdoc IVault
    function disablePocket(uint88 pocketId) external onlyRole(POCKET_SETTER_ROLE) {
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
    function updateFeeRecipient(address newFeeRecipient) external onlyRole(FEE_SETTER_ROLE) {
        _updateFeeRecipient(newFeeRecipient);
    }

    /// @inheritdoc IVault
    function updateOracle(address newOracle) external onlyRole(ORACLE_SETTER_ROLE) {
        if (IOracle(newOracle).asset() != address(COLLATERAL)) revert IOracle.InvalidOracle();
        _updateOracle(newOracle);
    }

    /// @inheritdoc IVault
    function updateLiquidationThreshold(uint96 newLiquidationThreshold) external onlyRole(LIQUIDATION_SETTER_ROLE) {
        _updateLiquidationThreshold(newLiquidationThreshold);
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

    /// @inheritdoc IVault
    function withdraw(uint88 pocketId, uint256 amount, address to) external ensureLoanHealthy(msg.sender, pocketId) returns (uint256 shares) {
        _takeFee(msg.sender, pocketId);
        // @audit should be able to withdraw even if pocket is disabled
        IPocket pocket = _getVaultStorage().pockets[pocketId].pocket;
        shares = pocket.withdraw(msg.sender, amount, to);
        emit Withdrawn(msg.sender, pocketId, to, amount, shares);
    }

    /// @inheritdoc IVault
    function mint(uint88 pocketId, uint256 amount) external ensureLoanHealthy(msg.sender, pocketId) {
        MintData storage $ = _getVaultStorage().mintData;
        $.modifyPosition(_toMintId(msg.sender, pocketId), amount.toInt256());
        TCAPV2.mint(msg.sender, amount);
        emit Minted(msg.sender, pocketId, amount);
    }

    /// @inheritdoc IVault
    function burn(uint88 pocketId, uint256 amount) external {
        MintData storage $ = _getVaultStorage().mintData;
        uint256 mintId = _toMintId(msg.sender, pocketId);
        if ($.deposits[mintId].mintAmount < amount) revert InsufficientMintedAmount();
        $.modifyPosition(mintId, -amount.toInt256());
        TCAPV2.burn(msg.sender, amount);
        emit Burned(msg.sender, pocketId, amount);
    }

    /// @inheritdoc IVault
    function liquidate(address user, uint88 pocketId) external {
        _takeFee(user, pocketId);
        uint256 mintAmount = mintedAmountOf(user, pocketId);
        uint256 mintValue = mintedValueOf(mintAmount);
        uint256 collateralAmount = collateralOf(user, pocketId);
        uint256 collateralValue = collateralValueOf(collateralAmount);
        if (mintValue == 0 || collateralValue / mintValue >= liquidationThreshold()) revert LoanHealthy();
        _getPocket(pocketId).withdraw(user, collateralAmount, msg.sender);
        TCAPV2.burn(msg.sender, mintAmount);
    }

    /// @inheritdoc IVault
    function healthFactor(address user, uint88 pocketId) public view returns (uint256) {
        uint256 mintValue = mintedValueOfUser(user, pocketId);
        if (mintValue == 0) return type(uint256).max;
        return collateralValueOfUser(user, pocketId) * 1e18 / mintValue;
    }

    /// @inheritdoc IVault
    function collateralValueOf(uint256 amount) public view returns (uint256) {
        return amount * latestPrice() / 10 ** _getVaultStorage().oracle.assetDecimals();
    }

    /// @inheritdoc IVault
    function collateralValueOfUser(address user, uint88 pocketId) public view returns (uint256) {
        return collateralValueOf(collateralOf(user, pocketId));
    }

    /// @inheritdoc IVault
    function mintedValueOf(uint256 amount) public view returns (uint256) {
        return TCAPV2.latestPriceOf(amount);
    }

    /// @inheritdoc IVault
    function mintedValueOfUser(address user, uint88 pocketId) public view returns (uint256) {
        return mintedValueOf(mintedAmountOf(user, pocketId));
    }

    /// @inheritdoc IVault
    function collateralOf(address user, uint88 pocketId) public view returns (uint256) {
        return _getPocket(pocketId).balanceOf(user) - outstandingInterestOf(user, pocketId);
    }

    /// @inheritdoc IVault
    function mintedAmountOf(address user, uint88 pocketId) public view returns (uint256) {
        return _getVaultStorage().mintData.deposits[_toMintId(user, pocketId)].mintAmount;
    }

    /// @inheritdoc IVault
    function outstandingInterestOf(address user, uint88 pocketId) public view returns (uint256) {
        MintData storage $ = _getVaultStorage().mintData;
        uint256 interestAmount = $.interestOf(_toMintId(user, pocketId));
        return interestAmount * TCAPV2.latestPrice() / latestPrice();
    }

    /// @inheritdoc IVault
    function latestPrice() public view returns (uint256) {
        return _getVaultStorage().oracle.latestPrice();
    }

    /// @inheritdoc IVault
    function oracle() external view returns (address) {
        return address(_getVaultStorage().oracle);
    }

    /// @inheritdoc IVault
    function interestRate() external view returns (uint16) {
        return _getVaultStorage().mintData.feeData.fee;
    }

    /// @inheritdoc IVault
    function feeRecipient() external view returns (address) {
        return _getVaultStorage().feeRecipient;
    }

    /// @inheritdoc IVault
    function liquidationThreshold() public view returns (uint96) {
        return _getVaultStorage().liquidationThreshold;
    }

    /// @inheritdoc IVault
    function pockets(uint88 id) external view returns (IPocket) {
        return _getVaultStorage().pockets[id].pocket;
    }

    /// @inheritdoc IVault
    function pocketEnabled(uint88 id) external view returns (bool) {
        return _getVaultStorage().pockets[id].enabled;
    }

    function _takeFee(address user, uint88 pocketId) internal {
        IPocket pocket = _getPocket(pocketId);
        uint256 interest = outstandingInterestOf(user, pocketId);
        // todo check if interest exceeds balance necessary?
        VaultStorage storage $ = _getVaultStorage();
        address feeRecipient_ = $.feeRecipient;
        if (interest != 0 && feeRecipient_ != address(0)) {
            pocket.withdraw(user, interest, feeRecipient_);
        }
        $.mintData.resetInterestOf(_toMintId(user, pocketId));
    }

    function _updateInterestRate(uint16 fee) internal {
        VaultStorage storage $ = _getVaultStorage();
        $.mintData.setInterestRate(fee);
        emit InterestRateUpdated(fee);
    }

    function _updateFeeRecipient(address newFeeRecipient) internal {
        VaultStorage storage $ = _getVaultStorage();
        $.feeRecipient = newFeeRecipient;
        emit FeeRecipientUpdated(newFeeRecipient);
    }

    function _updateLiquidationThreshold(uint96 newLiquidationThreshold) internal {
        if (newLiquidationThreshold < Constants.MIN_LIQUIDATION_THRESHOLD || newLiquidationThreshold > Constants.MAX_LIQUIDATION_THRESHOLD) {
            revert InvalidValue();
        }
        VaultStorage storage $ = _getVaultStorage();
        $.liquidationThreshold = newLiquidationThreshold;
        emit LiquidationThresholdUpdated(newLiquidationThreshold);
    }

    function _updateOracle(address newOracle) internal {
        VaultStorage storage $ = _getVaultStorage();
        $.oracle = IOracle(newOracle);
        emit OracleUpdated(newOracle);
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
