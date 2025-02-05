// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ERC20Upgradeable as ERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {AccessControlUpgradeable as AccessControl} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {ITCAPV2, IVersioned} from "./interface/ITCAPV2.sol";
import {IOracle} from "./interface/IOracle.sol";
import {Roles} from "./lib/Constants.sol";

/// @title TCAP v2
/// @notice TCAP v2 is an index token that is pegged to the entire crypto market cap
contract TCAPV2 is ITCAPV2, ERC20, AccessControl {
    /// @custom:storage-location erc7201:tcapv2.storage.main
    struct TCAPV2Storage {
        mapping(address vault => uint256 amount) _mintedAmounts;
        IOracle oracle;
    }

    // keccak256(abi.encode(uint256(keccak256("tcapv2.storage.main")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant TCAPV2StorageLocation = 0x49c710835f557391deaa6abce7163dc90464df5e070a25601335cdac43861e00;

    function _getTCAPV2Storage() private pure returns (TCAPV2Storage storage $) {
        assembly {
            $.slot := TCAPV2StorageLocation
        }
    }

    constructor() {
        _disableInitializers();
    }

    /// @dev oracle needs to be set after deployment
    function initialize(address admin) external initializer {
        __ERC20_init("TCAP", "TCAP");
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    /// @inheritdoc ITCAPV2
    function setOracle(address newOracle) external onlyRole(Roles.ORACLE_SETTER_ROLE) {
        if (IOracle(newOracle).asset() != address(this)) revert IOracle.InvalidOracle();
        _setOracle(newOracle);
    }

    /// @inheritdoc ITCAPV2
    function mint(address to, uint256 amount) external onlyRole(Roles.VAULT_ROLE) {
        TCAPV2Storage storage $ = _getTCAPV2Storage();
        $._mintedAmounts[msg.sender] += amount;
        _mint(to, amount);
        emit Minted(msg.sender, to, amount);
    }

    /// @inheritdoc ITCAPV2
    function burn(address from, uint256 amount) external onlyRole(Roles.VAULT_ROLE) {
        TCAPV2Storage storage $ = _getTCAPV2Storage();
        if (amount > $._mintedAmounts[msg.sender]) revert BalanceExceeded(msg.sender);
        _burn(from, amount);
        $._mintedAmounts[msg.sender] -= amount;
        emit Burned(msg.sender, from, amount);
    }

    /// @inheritdoc ITCAPV2
    function mintedAmount(address vault) external view returns (uint256) {
        TCAPV2Storage storage $ = _getTCAPV2Storage();
        return $._mintedAmounts[vault];
    }

    /// @inheritdoc ITCAPV2
    function oracle() external view returns (address) {
        TCAPV2Storage storage $ = _getTCAPV2Storage();
        return address($.oracle);
    }

    /// @inheritdoc ITCAPV2
    function latestPrice() public view returns (uint256) {
        TCAPV2Storage storage $ = _getTCAPV2Storage();
        return $.oracle.latestPrice(false);
    }

    /// @inheritdoc ITCAPV2
    function latestPriceOf(uint256 amount) external view returns (uint256) {
        return amount * latestPrice() / 10 ** decimals();
    }

    function _setOracle(address newOracle) internal {
        TCAPV2Storage storage $ = _getTCAPV2Storage();
        $.oracle = IOracle(newOracle);
        emit OracleUpdated(newOracle);
    }

    /// @inheritdoc IVersioned
    function version() external pure returns (string memory) {
        return "1.0.0";
    }
}
