//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {AggregatorV3Interface} from "@chainlink/interfaces/feeds/AggregatorV3Interface.sol";

contract MockFeed is AggregatorV3Interface {
    uint256 constant DENOMINATOR = 10_000;
    uint256 internal _answer;
    uint256 priceMultiplier = 10_000;
    uint8 internal _feedDecimals = 8;

    constructor(uint256 price) {
        _answer = price;
    }

    function setPrice(uint256 price) external {
        _answer = price;
        priceMultiplier = 10_000;
    }

    function setMultiplier(uint256 multiplier) external {
        priceMultiplier = multiplier;
    }

    function decimals() external view returns (uint8) {
        return _feedDecimals;
    }

    function description() external pure returns (string memory) {
        return "";
    }

    function version() external pure returns (uint256) {
        return 1;
    }

    function getRoundData(uint80) external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) {
        return (0, int256(_answer * priceMultiplier / DENOMINATOR), 0, 0, 0);
    }

    function latestRoundData() external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) {
        return (0, int256(_answer * priceMultiplier / DENOMINATOR), 0, 0, 0);
    }
}
