// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {Constants} from "./Constants.sol";

library LiquidationLib {
    function healthFactor(uint256 mintAmount, uint256 tcapPrice, uint256 collateralAmount, uint256 collateralPrice, uint8 collateralDecimals)
        internal
        pure
        returns (uint256)
    {
        if (mintAmount == 0 || tcapPrice == 0) return type(uint256).max;
        return collateralAmount * collateralPrice * 1e18 / mintAmount / tcapPrice * 10 ** Constants.TCAP_DECIMALS / 10 ** collateralDecimals;
    }

    function liquidationReward(uint256 burnAmount, uint256 tcapPrice, uint256 collateralPrice, uint64 liquidationPenalty, uint8 collateralDecimals)
        internal
        pure
        returns (uint256)
    {
        return burnAmount * tcapPrice * (1e18 + liquidationPenalty) / collateralPrice / 1e18 * 10 ** collateralDecimals / 10 ** Constants.TCAP_DECIMALS;
    }

    function tokensRequiredForTargetHealthFactor(uint256 currentHealthFactor, uint256 targetHealthFactor, uint256 mintAmount, uint64 liquidationPenalty)
        internal
        pure
        returns (uint256)
    {
        if (currentHealthFactor >= targetHealthFactor) return 0;
        uint256 numerator = mintAmount * (targetHealthFactor - currentHealthFactor);
        // enforced when setting liquidation params
        assert(1e18 + liquidationPenalty < targetHealthFactor);
        uint256 denominator = targetHealthFactor - 1e18 - liquidationPenalty;
        return numerator / denominator;
    }
}
