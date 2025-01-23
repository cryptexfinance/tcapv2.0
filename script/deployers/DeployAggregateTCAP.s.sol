// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Script.sol";
import {AggregatorInterfaceTCAP} from "script/mocks/AggregateInterfaceTCAP.sol";

contract TCAPOracleDeployer is Script {
    using stdJson for string;

    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        AggregatorInterfaceTCAP tcapOralce = new AggregatorInterfaceTCAP();
        console.log("tcapOralce", address(tcapOralce));
        vm.stopBroadcast();
    }
}
