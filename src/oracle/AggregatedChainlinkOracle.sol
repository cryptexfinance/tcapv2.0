// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseOracleUSD} from "./BaseOracleUSD.sol";
import {AggregatorV3Interface} from "@chainlink/interfaces/feeds/AggregatorV3Interface.sol";

/// @title Aggregated Chainlink Oracle USD
/// @dev all oracles are priced in USD with 18 decimals
contract AggregatedChainlinkOracle is BaseOracleUSD {
    AggregatorV3Interface public immutable feed;
    uint256 public immutable feedDecimals;
    uint256 public immutable stalenessDelay;

    /// @dev the staleness delay should be set relative to the heartbeat of the feed
    constructor(address feed_, address token, uint256 stalenessDelay_) BaseOracleUSD(token) {
        feed = AggregatorV3Interface(feed_);
        feedDecimals = feed.decimals();
        stalenessDelay = stalenessDelay_;
    }

    function latestPrice(bool checkStaleness) public view virtual override returns (uint256) {
        (, int256 answer,, uint256 updatedAt,) = feed.latestRoundData();
        // @audit in case of a stale oracle do not revert because it would prevent users from withdrawing
        // @audit only check staleness during minting to ensure staleness of price doesn't allow for arbitrage
        if (checkStaleness) {
            if (updatedAt < block.timestamp - stalenessDelay) {
                revert StaleOracle();
            }
        }
        assert(answer > 0);
        // @audit feed decimals cannot exceed 18
        uint256 adjustedDecimalsAnswer = uint256(answer) * 10 ** (18 - feedDecimals);
        return adjustedDecimalsAnswer;
    }
}
