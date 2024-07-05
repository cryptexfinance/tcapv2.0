// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {AccessControlUpgradeable as AccessControl} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {ITCAPV2} from "./interface/ITCAPV2.sol";
import {IVault} from "./interface/IVault.sol";
import {FeeCalculatorLib} from "./lib/FeeCalculatorLib.sol";

contract Vault is IVault, AccessControl {
    using FeeCalculatorLib for MintData;

    struct Deposit {
        address user;
        uint88 pocketId;
        bool enabled;
        uint256 mintAmount;
        uint256 feeIndex;
        uint256 accruedInterest;
    }

    struct Pocket {
        address pocket;
        bool enabled;
    }

    struct FeeData {
        uint256 index;
        uint16 fee;
        uint40 lastUpdated;
    }

    struct MintData {
        mapping(uint256 depositId => Deposit deposit) deposits;
        FeeData feeData;
        uint256 totalMinted;
    }

    /// @custom:storage-location erc7201:tcapv2.storage.vault
    struct VaultStorage {
        mapping(uint88 pocketId => Pocket pocket) pockets;
        uint88 pocketCounter;
        uint256 depositCounter;
        MintData depositData;
    }

    // keccak256(abi.encode(uint256(keccak256("tcapv2.storage.vault")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant VaultStorageLocation = 0xead32f79207e43129359e4c6890b619e37e73a4cc1d61050c081a5aea1b4df00;
    bytes32 public constant FEE_SETTER_ROLE = keccak256("FEE_SETTER_ROLE");
    ITCAPV2 public immutable tCAPV2;

    constructor(ITCAPV2 _tCAPV2) {
        tCAPV2 = _tCAPV2;
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

    function addPocket(address pocket) external onlyRole(DEFAULT_ADMIN_ROLE) returns (uint88 pocketId) {
        if (pocket == address(0)) revert InvalidValue();
        VaultStorage storage $ = _getVaultStorage();
        pocketId = $.pocketCounter++;
        $.pockets[pocketId] = Pocket({pocket: pocket, enabled: true});
        emit PocketAdded(pocketId, pocket);
    }

    function removePocket(uint88 pocketId) external onlyRole(DEFAULT_ADMIN_ROLE) {
        VaultStorage storage $ = _getVaultStorage();
        if (!$.pockets[pocketId].enabled) revert PocketNotEnabled(pocketId);
        $.pockets[pocketId].enabled = false;
        emit PocketDisabled(pocketId);
    }

    function updateInterestRate(uint16 fee) external onlyRole(FEE_SETTER_ROLE) {
        _updateInterestRate(fee);
    }

    function mint(uint256 mintAmount, uint256 collateralAmount, uint88 pocketId) external returns (uint256 depositId) {
        // TODO: transfer funds to pocket
        VaultStorage storage $ = _getVaultStorage();
        if (!$.pockets[pocketId].enabled) revert PocketNotEnabled(pocketId);
        depositId = ++$.depositCounter;
        $.depositData.registerDeposit(depositId, msg.sender, mintAmount, pocketId);
        emit Deposited(msg.sender, pocketId, depositId, mintAmount, collateralAmount);
    }

    function _updateInterestRate(uint16 fee) internal {
        VaultStorage storage $ = _getVaultStorage();
        $.depositData.setInterestRate(fee);
        emit InterestRateUpdated(fee);
    }

    function version() public pure returns (string memory) {
        return "1.0.0";
    }
}
