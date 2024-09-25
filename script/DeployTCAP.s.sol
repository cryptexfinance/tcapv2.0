// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Script.sol";
import "./deployers/TCAPV2Deployer.s.sol";
import {TCAPTargetOracle} from "../src/oracle/TCAPTargetOracle.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {TransparentUpgradeableProxy, ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {AggregatorV3Interface} from "@chainlink/interfaces/feeds/AggregatorV3Interface.sol";
import {Roles} from "../src/lib/Constants.sol";

contract Deploy is Script, TCAPV2Deployer {
    using stdJson for string;

    function run() public {
        // Final values for deployment tbd
        address proxyAdminOwner = address(1);
        address admin = address(2);
        AggregatorV3Interface oracleFeed = AggregatorV3Interface(address(3));
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

        TCAPV2(tcap).grantRole(Roles.ORACLE_SETTER_ROLE, tmpAdmin);
        TCAPTargetOracle oracle = new TCAPTargetOracle(ITCAPV2(tcap), address(oracleFeed));
        TCAPV2(tcap).setOracle(address(oracle));
        TCAPV2(tcap).grantRole(Roles.DEFAULT_ADMIN_ROLE, admin);
        TCAPV2(tcap).revokeRole(Roles.ORACLE_SETTER_ROLE, tmpAdmin);
        TCAPV2(tcap).revokeRole(Roles.DEFAULT_ADMIN_ROLE, tmpAdmin);
        emit Deployed(address(tcap), implementation);
    }
}
