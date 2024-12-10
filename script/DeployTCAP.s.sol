// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Script.sol";
import {TCAPTargetOracle} from "../src/oracle/TCAPTargetOracle.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {TransparentUpgradeableProxy, ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {AggregatorV3Interface} from "@chainlink/interfaces/feeds/AggregatorV3Interface.sol";
import {Roles} from "../src/lib/Constants.sol";
import {TCAPV2, ITCAPV2} from "../src/TCAPV2.sol";

contract Deploy is Script {
    using stdJson for string;

    function run() public {
        address proxyAdminOwner = 0x570f581D23a2AB09FD1990279D9DB6f5DcE18F4A;
        address admin = 0x570f581D23a2AB09FD1990279D9DB6f5DcE18F4A;
        AggregatorV3Interface oracleFeed = AggregatorV3Interface(0x962C0Df8Ca7f7C682B3872ccA31Ea9c8999ab23c);
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        new TCAPDeployer(proxyAdminOwner, admin, oracleFeed);
        vm.stopBroadcast();
    }
}

/// @dev ensures that the contracts and permissions are set up correctly
contract TCAPDeployer {
    event Deployed(address indexed tcap, address indexed implementation);

    constructor(address proxyAdminOwner, address admin, AggregatorV3Interface oracleFeed) {
        address tmpAdmin = address(this);
        bytes memory initData = abi.encodeCall(TCAPV2.initialize, (tmpAdmin));

        address implementation = address(new TCAPV2());
        TCAPV2 tcap = TCAPV2(address(new TransparentUpgradeableProxy(implementation, proxyAdminOwner, initData)));

        TCAPV2(tcap).grantRole(Roles.DEFAULT_ADMIN_ROLE, admin);
        TCAPV2(tcap).grantRole(Roles.ORACLE_SETTER_ROLE, admin);
        TCAPV2(tcap).grantRole(Roles.ORACLE_SETTER_ROLE, tmpAdmin);
        TCAPTargetOracle oracle = new TCAPTargetOracle(ITCAPV2(tcap), address(oracleFeed), 5 days);
        TCAPV2(tcap).setOracle(address(oracle));
        TCAPV2(tcap).revokeRole(Roles.ORACLE_SETTER_ROLE, tmpAdmin);
        TCAPV2(tcap).revokeRole(Roles.DEFAULT_ADMIN_ROLE, tmpAdmin);
        emit Deployed(address(tcap), implementation);
    }
}
