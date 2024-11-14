// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Script.sol";
import {TCAPTargetOracle} from "src/oracle/TCAPTargetOracle.sol";
import {AggregatorV3Interface} from "@chainlink/interfaces/feeds/AggregatorV3Interface.sol";
import {Roles} from "src/lib/Constants.sol";
import {TCAPV2, ITCAPV2} from "src/TCAPV2.sol";
import {TCAPTargetOracle} from "src/oracle/TCAPTargetOracle.sol";
import {AggregatorInterfaceTCAP} from "script/mocks/AggregateInterfaceTCAP.sol";

abstract contract TCAPOracleDeployer is Script {
    using stdJson for string;

    function deployTCAPOracle() internal {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        address tcapV2Address = vm.getDeployment("TCAPV2");
        AggregatorInterfaceTCAP tcapOralce = new AggregatorInterfaceTCAP();
        new TCAPTargetOracle(ITCAPV2(tcapV2Address), address(tcapOralce), 1 days);
        vm.stopBroadcast();
    }
}
