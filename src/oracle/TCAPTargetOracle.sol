// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ITCAPV2} from "../interface/ITCAPV2.sol";
import {AggregatedChainlinkOracle} from "./AggregatedChainlinkOracle.sol";
import {Constants} from "../lib/Constants.sol";

/// @title TCAP Target Oracle
/// @dev Returns the target price of the TCAP token
contract TCAPTargetOracle is AggregatedChainlinkOracle {
    constructor(ITCAPV2 tcap, address feed_) AggregatedChainlinkOracle(feed_, address(tcap)) {}

    // @dev feed decimals cannot exceed 18
    function latestPrice(bool checkStaleness) public view virtual override returns (uint256) {
        return super.latestPrice(checkStaleness) / Constants.DIVISOR;
    }
}
