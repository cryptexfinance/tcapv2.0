// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Script.sol";
import {AggregatorInterfaceUSDC} from "script/mocks/AggregateInterfaceUSDC.sol";
import {AggregatedChainlinkOracle} from "src/oracle/AggregatedChainlinkOracle.sol";

abstract contract USDCOracleDeployer is Script {
    using stdJson for string;

    function deployUSDCOracle() internal {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        AggregatorInterfaceUSDC usdcOralceFeed = new AggregatorInterfaceUSDC();
        address usdcAddress = 0x94a9D9AC8a22534E3FaCa9F4e7F2E2cf85d5E4C8;
        new AggregatedChainlinkOracle(address(usdcOralceFeed), usdcAddress, 1 days);
        vm.stopBroadcast();
    }
}
