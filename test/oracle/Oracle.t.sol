// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test} from "forge-std/Test.sol";
import "test/util/TestHelpers.sol";

import {BaseOracleUSD} from "../../src/oracle/BaseOracleUSD.sol";
import {AggregatedChainlinkOracle} from "../../src/oracle/AggregatedChainlinkOracle.sol";
import {TCAPTargetOracle} from "../../src/oracle/TCAPTargetOracle.sol";
import {MockFeed} from "../mock/MockFeed.sol";
import {MockCollateral} from "../mock/MockCollateral.sol";
import "script/deployers/TCAPV2Deployer.s.sol";
import {Constants} from "../../src/lib/Constants.sol";

contract BaseOracleUSDTest is Test, TestHelpers, TCAPV2Deployer {
    function test_InitializeCorrectly() public {
        MockCollateral collateral = new MockCollateral();
        MockFeed feed = new MockFeed(1);
        AggregatedChainlinkOracle oracle = new AggregatedChainlinkOracle(address(feed), address(collateral));
        assertEq(address(oracle.feed()), address(feed));
        assertEq(oracle.feedDecimals(), feed.decimals());
        assertEq(address(oracle.asset()), address(collateral));
    }

    function test_InitializeTCAPTargetOracleCorrectly() public {
        deployTCAPV2Transparent(makeAddr("admin"), makeAddr("admin"));
        uint256 price = 1e50;
        MockFeed feed = new MockFeed(price);
        TCAPTargetOracle oracle = new TCAPTargetOracle(tCAPV2, address(feed));
        assertEq(price * 10 ** (18 - feed.decimals()) / Constants.DIVISOR, oracle.latestPrice());
    }
}
