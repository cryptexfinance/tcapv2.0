// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseOracleUSD} from "./BaseOracleUSD.sol";
import {AggregatorV3Interface} from "@chainlink/interfaces/feeds/AggregatorV3Interface.sol";

/// @title Aggregated Chainlink Oracle USD
/// @dev all oracles are priced in USD with 18 decimals
contract AggregatedChainlinkOracle is BaseOracleUSD {
    AggregatorV3Interface public immutable feed;
    int256 private immutable MIN_AMOUNT;
    int256 private immutable MAX_AMOUNT;

    uint256 public immutable feedDecimals;
    uint256 public immutable stalenessDelay;

    /// @dev the staleness delay should be set relative to the heartbeat of the feed
    constructor(address feed_, address token, uint256 stalenessDelay_) BaseOracleUSD(token) {
        feed = AggregatorV3Interface(feed_);
        feedDecimals = feed.decimals();
        stalenessDelay = stalenessDelay_;
        // get min and max answer from the aggregator, set the min amount to the reported min amount, set the max amount to the reported max amount in order to revert if chainlink reports exactly the min or max amount, which means the min or max amount are likely exceeded
        (bool success, bytes memory data) = address(feed_).call(abi.encodeWithSignature("aggregator()"));
        assert(success);
        address aggregator = abi.decode(data, (address));
        (success, data) = address(aggregator).call(abi.encodeWithSignature("minAnswer()"));
        assert(success);
        int192 minAmount = abi.decode(data, (int192));
        assert(minAmount > 0);
        MIN_AMOUNT = int256(minAmount);
        (success, data) = address(aggregator).call(abi.encodeWithSignature("maxAnswer()"));
        assert(success);
        int192 maxAmount = abi.decode(data, (int192));
        assert(maxAmount > 2 && maxAmount > minAmount);
        MAX_AMOUNT = int256(maxAmount);
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
        // revert if the answer is MIN_AMOUNT or less
        // revert if the answer is MAX_AMOUNT or more
        assert(answer > MIN_AMOUNT && answer < MAX_AMOUNT);
        // @audit feed decimals cannot exceed 18
        uint256 adjustedDecimalsAnswer = uint256(answer) * 10 ** (18 - feedDecimals);
        return adjustedDecimalsAnswer;
    }
}
