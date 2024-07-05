// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {Vault, IVault, FeeCalculatorLib} from "../src/lib/FeeCalculatorLib.sol";

abstract contract Uninitialized is Test {
    struct Deposit {
        address user;
        uint256 amount;
    }

    Vault.MintData data;

    function setUp() public virtual {}
}

abstract contract Deposited is Uninitialized {
    using FeeCalculatorLib for Vault.MintData;

    struct FeePeriod {
        uint16 fee;
        uint40 duration;
    }

    Deposit[] deposits;

    function setUp() public virtual override {
        super.setUp();
        data.setInterestRate(1000); // default to 10% interest rate
        uint256 maxAmount = 100 ether;
        deposits.push(Deposit({user: makeAddr("alice"), amount: uint256(keccak256("alice")) % maxAmount}));
        deposits.push(Deposit({user: makeAddr("bob"), amount: uint256(keccak256("bob")) % maxAmount}));
        deposits.push(Deposit({user: makeAddr("charlie"), amount: uint256(keccak256("charlie")) % maxAmount}));
        deposits.push(Deposit({user: makeAddr("david"), amount: uint256(keccak256("david")) % maxAmount}));
        for (uint256 i = 0; i < deposits.length; i++) {
            data.registerDeposit(i, deposits[i].user, deposits[i].amount, 0);
        }
    }

    function calculateInterestRate(uint256 amount, uint16 fee, uint40 duration) internal pure returns (uint256) {
        return amount * fee * duration / (365 days * 10_000);
    }

    function format(FeePeriod memory period) internal pure returns (uint16 fee, uint40 duration) {
        fee = uint16(bound(uint256(fee), 0, 10_000));
        duration = period.duration;
    }
}

contract DepositTest is Uninitialized {
    using FeeCalculatorLib for Vault.MintData;

    function test_fuzz_registerDeposit(Deposit[] memory deposits) public {
        vm.assume(deposits.length > 0);
        uint256 sum = 0;
        for (uint256 i = 0; i < deposits.length; i++) {
            vm.assume(deposits[i].user != address(0));
            deposits[i].amount = bound(deposits[i].amount, 1, type(uint256).max / (deposits.length * 1e9));
            data.registerDeposit(i, deposits[i].user, deposits[i].amount, 0);
            sum += deposits[i].amount;
        }
        assertEq(data.totalMinted, sum);
    }

    function test_revertIf_userIsZeroAddress() public {
        vm.expectRevert(IVault.InvalidValue.selector);
        data.registerDeposit(0, address(0), 1, 0);
    }

    function test_fuzz_revertIf_depositIdAlreadyUsed(uint256 depositId) public {
        data.registerDeposit(depositId, address(1), 1, 0);
        vm.expectRevert(abi.encodeWithSelector(IVault.DepositIdAlreadyUsed.selector, depositId));
        data.registerDeposit(depositId, address(1), 1, 0);
    }
}

contract InterestRateCalculationTest is Deposited {
    using FeeCalculatorLib for Vault.MintData;

    function test_fuzz_calculateInterestCorrectly(FeePeriod memory period) public {
        (uint16 fee, uint40 duration) = format(period);
        data.setInterestRate(fee);
        skip(duration);
        for (uint256 i = 0; i < deposits.length; i++) {
            uint256 expectedFee = calculateInterestRate(deposits[i].amount, fee, duration);
            uint256 actualFee = data.outstandingInterest(i);
            assertEq(actualFee, expectedFee);
        }
    }

    function test_fuzz_calculateMultipleFeePeriodsCorrectly(uint256 depositId, FeePeriod[] memory periods) public {
        depositId = bound(depositId, 0, deposits.length - 1);
        uint256 totalFee = 0;
        for (uint256 i = 0; i < periods.length; i++) {
            (uint16 fee, uint40 duration) = format(periods[i]);
            data.setInterestRate(fee);
            skip(duration);
            totalFee += calculateInterestRate(deposits[depositId].amount, fee, duration);
        }
        assertEq(data.outstandingInterest(depositId), totalFee);
    }

    function test_fuzz_calculateInterestCorrectlyForChangingMintAmounts(uint256 depositId, FeePeriod[] memory periods) public {
        depositId = bound(depositId, 0, deposits.length - 1);
        uint256 totalFee = 0;
        int256 currentAmount = int256(deposits[depositId].amount);
        for (uint256 i = 0; i < periods.length; i++) {
            int256 balanceChange = bound(int256(uint256(keccak256(abi.encode(i, depositId)))), -1e18, 1e18);
            currentAmount += balanceChange;
            data.modifyPosition(depositId, balanceChange);
            (uint16 fee, uint40 duration) = format(periods[i]);
            data.setInterestRate(fee);
            skip(duration);
            totalFee += calculateInterestRate(uint256(currentAmount), fee, duration);
        }
        assertEq(data.outstandingInterest(depositId), totalFee);
    }
}
