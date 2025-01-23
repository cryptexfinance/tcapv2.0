// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {TCAPTargetOracle} from "../src/oracle/TCAPTargetOracle.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {TransparentUpgradeableProxy, ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {AggregatorV3Interface} from "@chainlink/interfaces/feeds/AggregatorV3Interface.sol";
import {Roles} from "../src/lib/Constants.sol";
import {TCAPV2, ITCAPV2} from "../src/TCAPV2.sol";

contract Deploy is Script {
    using stdJson for string;
    event Deployed(address indexed tcap, address indexed implementation);

    function run() public {
        address proxyAdminOwner = 0x570f581D23a2AB09FD1990279D9DB6f5DcE18F4A;
        address admin = 0x30Abf2e1ac3A52c8c3F99078d1D52667d656C84B;
        AggregatorV3Interface oracleFeed = AggregatorV3Interface(0x5b9C9836eceC3Eb097FBE6b6436b477942F4e525);

        uint256 pk = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(pk);
        console.log('pk address', vm.addr(pk));

        bytes memory initData = abi.encodeCall(TCAPV2.initialize, (admin));

        address implementation = address(new TCAPV2());
        TCAPV2 tcap = TCAPV2(address(new TransparentUpgradeableProxy(implementation, proxyAdminOwner, initData)));
        console.log("deployed TCAP at: ", address(tcap));

        TCAPV2(tcap).grantRole(Roles.ORACLE_SETTER_ROLE, admin);

        TCAPTargetOracle oracle = new TCAPTargetOracle(ITCAPV2(tcap), address(oracleFeed), 5 days);
        TCAPV2(tcap).setOracle(address(oracle));
        emit Deployed(address(tcap), implementation);

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
        console.log("deployed TCAP at: ", address(tcap));

        TCAPV2(tcap).grantRole(Roles.DEFAULT_ADMIN_ROLE, admin);
        TCAPV2(tcap).grantRole(Roles.DEFAULT_ADMIN_ROLE, proxyAdminOwner);
        TCAPV2(tcap).grantRole(Roles.ORACLE_SETTER_ROLE, admin);
        TCAPV2(tcap).grantRole(Roles.ORACLE_SETTER_ROLE, tmpAdmin);

        TCAPTargetOracle oracle = new TCAPTargetOracle(ITCAPV2(tcap), address(oracleFeed), 5 days);
        TCAPV2(tcap).setOracle(address(oracle));
        TCAPV2(tcap).revokeRole(Roles.ORACLE_SETTER_ROLE, tmpAdmin);
        TCAPV2(tcap).revokeRole(Roles.DEFAULT_ADMIN_ROLE, tmpAdmin);
        emit Deployed(address(tcap), implementation);
    }
}
