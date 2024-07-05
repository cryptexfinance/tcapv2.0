// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IVault} from "../interface/IVault.sol";
import {Vault} from "../Vault.sol";

library FeeCalculatorLib {
    uint256 private constant MAX_FEE = 10_000; // 100%

    function registerDeposit(Vault.MintData storage $, uint256 depositId, address user, uint256 amount, uint88 pocketId) internal {
        if (user == address(0)) revert IVault.InvalidValue();
        uint256 index = updateFeeIndex($);
        if ($.deposits[depositId].user != address(0)) revert IVault.DepositIdAlreadyUsed(depositId);
        $.deposits[depositId] = Vault.Deposit({user: user, pocketId: pocketId, enabled: true, mintAmount: amount, feeIndex: index, accruedInterest: 0});
        $.totalMinted += amount;
    }

    function modifyPosition(Vault.MintData storage $, uint256 depositId, int256 amount) internal {
        uint256 currentIndex = feeIndex($);
        $.deposits[depositId].accruedInterest += outstandingInterest($, currentIndex, depositId);
        $.deposits[depositId].feeIndex = currentIndex;
        uint256 currentAmount = $.deposits[depositId].mintAmount;
        uint256 totalMinted = $.totalMinted;
        assert(totalMinted < uint256(type(int256).max));
        int256 newAmount = int256(currentAmount) + amount;
        int256 newTotalMinted = int256(totalMinted) + amount;
        assert(newAmount > 0);
        $.deposits[depositId].mintAmount = uint256(newAmount);
        $.totalMinted = uint256(newTotalMinted);
    }

    function feeIndex(Vault.MintData storage $) internal view returns (uint256) {
        return $.feeData.index + (block.timestamp - $.feeData.lastUpdated) * $.feeData.fee * MULTIPLIER() / (365 days * MAX_FEE);
    }

    function updateFeeIndex(Vault.MintData storage $) internal returns (uint256 index) {
        index = feeIndex($);
        $.feeData.index = index;
        $.feeData.lastUpdated = uint40(block.timestamp);
    }

    function setInterestRate(Vault.MintData storage $, uint16 fee) internal {
        updateFeeIndex($);
        if (fee > MAX_FEE) revert IVault.InvalidValue();
        $.feeData.fee = fee;
    }

    function outstandingInterest(Vault.MintData storage $, uint256 depositId) internal view returns (uint256 interest) {
        return outstandingInterest($, feeIndex($), depositId);
    }

    function outstandingInterest(Vault.MintData storage $, uint256 index, uint256 depositId) internal view returns (uint256 interest) {
        uint256 userIndex = $.deposits[depositId].feeIndex;
        return $.deposits[depositId].mintAmount * (index - userIndex) / MULTIPLIER();
    }

    /// @dev ensures correct calculation for small amounts
    function MULTIPLIER() private pure returns (uint256) {
        return 1e30;
    }
}
