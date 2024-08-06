// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {Vault, IVault, FeeCalculatorLib} from "../../src/lib/FeeCalculatorLib.sol";

abstract contract Uninitialized is Test {
    using FeeCalculatorLib for Vault.MintData;

    struct Deposit {
        uint256 id;
        uint256 amount;
    }

    struct FeePeriod {
        uint16 fee;
        uint40 duration;
    }

    uint256 MAX_AMOUNT = 10_000 ether;

    Vault.MintData data;

    function setUp() public virtual {
        data.setInterestRate(1000); // default to 10% interest rate
    }

    function calculateInterestRate(uint256 amount, uint16 fee, uint40 duration) internal pure returns (uint256) {
        return amount * fee * duration / (365 days * 10_000);
    }

    function format(FeePeriod memory period) internal pure returns (uint16 fee, uint40 duration) {
        fee = uint16(bound(uint256(fee), 0, 10_000));
        duration = period.duration;
    }

    function setUpDeposits(uint256[] memory depositSeeds) internal returns (Deposit[] memory) {
        vm.assume(depositSeeds.length != 0);
        Deposit[] memory deposits = new Deposit[](depositSeeds.length);
        for (uint256 i = 0; i < depositSeeds.length; i++) {
            uint256 amount = uint256(keccak256(abi.encode(depositSeeds[i]))) % MAX_AMOUNT;
            data.modifyPosition(i, int256(amount));
            deposits[i] = Deposit({id: i, amount: amount});
        }
        return deposits;
    }
}

contract InterestRateCalculationTest is Uninitialized {
    using FeeCalculatorLib for Vault.MintData;

    function test_fuzz_calculateInterestCorrectly(uint256[] memory depositSeeds, FeePeriod memory period) public {
        Deposit[] memory deposits = setUpDeposits(depositSeeds);
        (uint16 fee, uint40 duration) = format(period);
        data.setInterestRate(fee);
        skip(duration);
        for (uint256 i = 0; i < deposits.length; i++) {
            uint256 expectedFee = calculateInterestRate(deposits[i].amount, fee, duration);
            uint256 actualFee = data.interestOf(i);
            assertEq(actualFee, expectedFee);
        }
    }

    function test_fuzz_calculateMultipleFeePeriodsCorrectly(uint256[] memory depositSeeds, uint256 mintId, FeePeriod[] memory periods) public {
        Deposit[] memory deposits = setUpDeposits(depositSeeds);
        mintId = bound(mintId, 0, deposits.length - 1);
        uint256 totalFee = 0;
        for (uint256 i = 0; i < periods.length; i++) {
            (uint16 fee, uint40 duration) = format(periods[i]);
            data.setInterestRate(fee);
            skip(duration);
            totalFee += calculateInterestRate(deposits[mintId].amount, fee, duration);
        }
        assertEq(data.interestOf(mintId), totalFee);
    }

    function test_fuzz_calculateInterestCorrectlyForChangingMintAmounts(uint256[] memory depositSeeds, uint256 mintId, FeePeriod[] memory periods) public {
        Deposit[] memory deposits = setUpDeposits(depositSeeds);
        mintId = bound(mintId, 0, deposits.length - 1);
        uint256 totalFee = 0;
        int256 currentAmount = int256(deposits[mintId].amount);
        for (uint256 i = 0; i < periods.length; i++) {
            int256 balanceChange = bound(int256(uint256(keccak256(abi.encode(i, mintId)))), -1e18, 1e18);
            currentAmount += balanceChange;
            data.modifyPosition(mintId, balanceChange);
            (uint16 fee, uint40 duration) = format(periods[i]);
            data.setInterestRate(fee);
            skip(duration);
            totalFee += calculateInterestRate(uint256(currentAmount), fee, duration);
        }
        assertEq(data.interestOf(mintId), totalFee);
    }
}
