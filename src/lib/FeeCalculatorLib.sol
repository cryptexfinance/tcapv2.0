// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IVault} from "../interface/IVault.sol";
import {Vault} from "../Vault.sol";
import {Constants} from "./Constants.sol";

library FeeCalculatorLib {
    function modifyPosition(Vault.MintData storage $, uint256 mintId, int256 amount) internal {
        uint256 currentIndex = feeIndex($);
        $.deposits[mintId].accruedInterest += outstandingInterest($, currentIndex, mintId);
        $.deposits[mintId].feeIndex = currentIndex;
        uint256 currentAmount = $.deposits[mintId].mintAmount;
        int256 newAmount = int256(currentAmount) + amount;
        assert(newAmount >= 0);
        $.deposits[mintId].mintAmount = uint256(newAmount);
    }

    function feeIndex(Vault.MintData storage $) internal view returns (uint256) {
        return $.feeData.index + (block.timestamp - $.feeData.lastUpdated) * $.feeData.fee * MULTIPLIER() / (365 days * Constants.MAX_FEE);
    }

    function updateFeeIndex(Vault.MintData storage $) internal returns (uint256 index) {
        index = feeIndex($);
        $.feeData.index = index;
        $.feeData.lastUpdated = uint40(block.timestamp);
    }

    function setInterestRate(Vault.MintData storage $, uint16 fee) internal {
        updateFeeIndex($);
        $.feeData.fee = fee;
    }

    function interestOf(Vault.MintData storage $, uint256 mintId) internal view returns (uint256 interest) {
        return $.deposits[mintId].accruedInterest + outstandingInterest($, feeIndex($), mintId);
    }

    function resetInterestOf(Vault.MintData storage $, uint256 mintId) internal {
        $.deposits[mintId].accruedInterest = 0;
        $.deposits[mintId].feeIndex = feeIndex($);
    }

    function outstandingInterest(Vault.MintData storage $, uint256 index, uint256 mintId) private view returns (uint256 interest) {
        uint256 userIndex = $.deposits[mintId].feeIndex;
        return $.deposits[mintId].mintAmount * (index - userIndex) / MULTIPLIER();
    }

    /// @dev ensures correct calculation for small amounts
    function MULTIPLIER() private pure returns (uint256) {
        return 1e30;
    }
}
