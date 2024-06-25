// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {AccessControlUpgradeable as AccessControl} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {ITCAPV2} from "./interface/ITCAPV2.sol";
import {IVault} from "./interface/IVault.sol";

contract Vault is IVault, AccessControl {
    /// @custom:storage-location erc7201:tcapv2.storage.vault
    struct VaultStorage {
        mapping(uint256 pocketId => address pocket) _pockets;
        uint256 pocketCounter;
    }

    // keccak256(abi.encode(uint256(keccak256("tcapv2.storage.vault")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant VaultStorageLocation = 0xead32f79207e43129359e4c6890b619e37e73a4cc1d61050c081a5aea1b4df00;
    ITCAPV2 public immutable tCAPV2;

    constructor(ITCAPV2 _tCAPV2) {
        tCAPV2 = _tCAPV2;
        _disableInitializers();
    }

    function initialize(address admin) public initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    function _getVaultStorage() private pure returns (VaultStorage storage $) {
        assembly {
            $.slot := VaultStorageLocation
        }
    }

    function addPocket(address pocket) external onlyRole(DEFAULT_ADMIN_ROLE) returns (uint256 pocketId) {
        VaultStorage storage $ = _getVaultStorage();
        pocketId = $.pocketCounter++;
        $._pockets[pocketId] = pocket;
        emit PocketAdded(pocketId, pocket);
    }

    function version() public pure returns (string memory) {
        return "1.0.0";
    }
}
