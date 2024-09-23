// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "forge-std/Test.sol";
import {LiquidationLib} from "../../src/lib/LiquidationLib.sol";

contract LiquidationLibTest is Test {
    /// forge-config: default.fuzz.runs = 100
    function test_ffi_liquidationReward(uint256 burnAmount, uint256 tcapPrice, uint256 collateralPrice, uint64 liquidationFee, uint8 collateralDecimals)
        public
    {
        collateralDecimals = uint8(bound(collateralDecimals, 6, 18));
        burnAmount = bound(burnAmount, 0, 1000e18);
        tcapPrice = bound(tcapPrice, 1e16, 10_000e18);
        collateralPrice = bound(collateralPrice, 1e16, 10_000e18);
        liquidationFee = uint64(bound(liquidationFee, 1e16, 1e18));

        string[] memory cmds = new string[](7);
        cmds[0] = "python3";
        cmds[1] = "test/python/calcLiquidationReward.py";
        cmds[2] = vm.toString(burnAmount);
        cmds[3] = vm.toString(tcapPrice);
        cmds[4] = vm.toString(collateralPrice);
        cmds[5] = vm.toString(liquidationFee);
        cmds[6] = vm.toString(collateralDecimals);
        bytes memory res = vm.ffi(cmds);
        uint256 liquidationReward = LiquidationLib.liquidationReward(burnAmount, tcapPrice, collateralPrice, liquidationFee, collateralDecimals);
        uint256 expectedLiquidationReward = abi.decode(res, (uint256));
        // allow 0.000001% error due to rounding
        assertApproxEqRel(liquidationReward, expectedLiquidationReward, 0.000001e16);
    }

    /// forge-config: default.fuzz.runs = 100
    function test_ffi_tokensRequiredForTargetHealthFactor(
        uint256 targetHealthFactor,
        uint256 mintAmount,
        uint256 tcapPrice,
        uint256 collateralAmount,
        uint256 collateralPrice,
        uint64 liquidationPenalty,
        uint8 collateralDecimals
    ) public {
        // @audit smaller decimals than 6 can lead to bigger errors due to rounding
        collateralDecimals = uint8(bound(collateralDecimals, 6, 18));
        mintAmount = bound(mintAmount, 1e18, 1000e18);
        tcapPrice = bound(tcapPrice, 1, 100e18);
        collateralAmount = bound(collateralAmount, 10 ** collateralDecimals, 100_000 * 10 ** collateralDecimals);
        collateralPrice = bound(collateralPrice, 1e18, 10_000e18);
        liquidationPenalty = uint64(bound(liquidationPenalty, 0, 0.5e18));
        targetHealthFactor = bound(targetHealthFactor, 1e18 + liquidationPenalty + 1e7, 2e18 + 1);

        string[] memory cmds = new string[](9);
        cmds[0] = "python3";
        cmds[1] = "test/python/calcTokensRequiredForTargetHF.py";
        cmds[2] = vm.toString(targetHealthFactor);
        cmds[3] = vm.toString(mintAmount);
        cmds[4] = vm.toString(tcapPrice);
        cmds[5] = vm.toString(collateralAmount);
        cmds[6] = vm.toString(collateralPrice);
        cmds[7] = vm.toString(liquidationPenalty);
        cmds[8] = vm.toString(collateralDecimals);
        bytes memory res = vm.ffi(cmds);

        uint256 currentHealthFactor = LiquidationLib.healthFactor(mintAmount, tcapPrice, collateralAmount, collateralPrice, collateralDecimals);
        uint256 tokensRequired = LiquidationLib.tokensRequiredForTargetHealthFactor(currentHealthFactor, targetHealthFactor, mintAmount, liquidationPenalty);

        uint256 expectedTokensRequired = abi.decode(res, (uint256));
        // allow 0.1% error due to rounding
        assertApproxEqRel(tokensRequired, expectedTokensRequired, 0.1e16);
    }
}
