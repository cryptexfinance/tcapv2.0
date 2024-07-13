// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ERC20Upgradeable as ERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {AccessControlUpgradeable as AccessControl} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {ITCAPV2, IVersioned} from "./interface/ITCAPV2.sol";

/// @title TCAP v2
/// @notice TCAP v2 is an index token that is pegged to the entire crypto market cap
contract TCAPV2 is ITCAPV2, ERC20, AccessControl {
    /// @custom:storage-location erc7201:tcapv2.storage.main
    struct TCAPV2Storage {
        mapping(address vault => uint256 amount) _mintedAmounts;
    }

    // keccak256(abi.encode(uint256(keccak256("tcapv2.storage.main")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant TCAPV2StorageLocation = 0x49c710835f557391deaa6abce7163dc90464df5e070a25601335cdac43861e00;
    bytes32 VAULT_ROLE = keccak256("VAULT_ROLE");

    function _getTCAPV2Storage() private pure returns (TCAPV2Storage storage $) {
        assembly {
            $.slot := TCAPV2StorageLocation
        }
    }

    constructor() {
        _disableInitializers();
    }

    function initialize(address admin) external initializer {
        __ERC20_init("TCAP", "TCAP");
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    /// @inheritdoc ITCAPV2
    function mint(address to, uint256 amount) external onlyRole(VAULT_ROLE) {
        _mint(to, amount);
        TCAPV2Storage storage $ = _getTCAPV2Storage();
        $._mintedAmounts[msg.sender] += amount;
        emit Minted(msg.sender, to, amount);
    }

    /// @inheritdoc ITCAPV2
    function burn(address from, uint256 amount) external onlyRole(VAULT_ROLE) {
        TCAPV2Storage storage $ = _getTCAPV2Storage();
        if (amount > $._mintedAmounts[msg.sender]) revert BalanceExceeded(msg.sender);
        _burn(from, amount);
        $._mintedAmounts[msg.sender] -= amount;
        emit Burned(msg.sender, from, amount);
    }

    /// @inheritdoc ITCAPV2
    function mintedAmount(address vault) external view returns (uint256) {
        // TODO: add mint cap?
        TCAPV2Storage storage $ = _getTCAPV2Storage();
        return $._mintedAmounts[vault];
    }

    /// @inheritdoc IVersioned
    function version() external pure returns (string memory) {
        return "1.0.0";
    }
}
