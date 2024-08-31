// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Constants {
    uint64 internal constant MIN_LIQUIDATION_THRESHOLD = 1e18;
    uint64 internal constant MAX_LIQUIDATION_THRESHOLD = 2e18;
    uint64 internal constant MAX_LIQUIDATION_PENALTY = 0.5e18;
    uint64 internal constant MIN_POST_LIQUIDATION_HEALTH_FACTOR = 0.01e18;
    uint64 internal constant MAX_POST_LIQUIDATION_HEALTH_FACTOR = 1e18;
    uint256 internal constant MAX_FEE = 10_000; // 100%
}
