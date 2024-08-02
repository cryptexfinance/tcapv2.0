// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ITCAPV2} from "../interface/ITCAPV2.sol";
import {AggregatedChainlinkOracle} from "./AggregatedChainlinkOracle.sol";

/// @title TCAP Target Oracle
/// @dev Returns the target price of the TCAP token
contract TCAPTargetOracle is AggregatedChainlinkOracle {
    uint256 private immutable DIVISOR;

    constructor(ITCAPV2 tcap, address feed, address token) AggregatedChainlinkOracle(feed, token) {
        DIVISOR = tcap.DIVISOR();
    }

    // @dev feed decimals cannot exceed 18
    function latestPrice() public view virtual override returns (uint256) {
        return super.latestPrice() / DIVISOR;
    }
}
