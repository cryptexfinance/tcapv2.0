// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseOracleUSD} from "./BaseOracleUSD.sol";
import {AggregatorV3Interface} from "@chainlink/interfaces/feeds/AggregatorV3Interface.sol";

/// @title Aggregated Chainlink Oracle USD
/// @dev all oracles are priced in USD with 18 decimals
contract AggregatedChainlinkOracle is BaseOracleUSD {
    AggregatorV3Interface internal immutable _feed;
    uint256 internal immutable _decimals;

    constructor(address feed, address token) BaseOracleUSD(token) {
        _feed = AggregatorV3Interface(feed);
        _decimals = _feed.decimals();
    }

    // @dev feed decimals cannot exceed 18
    function latestPrice() public view virtual override returns (uint256) {
        (, int256 answer,,,) = _feed.latestRoundData();
        assert(answer > 0);
        uint256 adjustedDecimalsAnswer = uint256(answer) * 10 ** (18 - _decimals);
        return adjustedDecimalsAnswer;
    }
}
