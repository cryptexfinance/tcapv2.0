// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BasePocket} from "./BasePocket.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {Constants} from "../lib/Constants.sol";
import {SafeTransferLib} from "solady/src/utils/SafeTransferLib.sol";
import {IVersioned} from "../interface/IVersioned.sol";

/// @title Base Pocket
/// @notice The default pocket that simply stores the underlying token in this contract
/// @dev assumes the underlying token is the same as the overlying token.
contract DefaultPocket is BasePocket {
    using SafeTransferLib for address;

    constructor(address vault_, address underlyingToken_) BasePocket(vault_, underlyingToken_, underlyingToken_) {}

    function initialize() public initializer {}

    function _onDeposit(uint256 amountUnderlying) internal pure override returns (uint256 amountOverlying) {
        amountOverlying = amountUnderlying;
    }

    function _onWithdraw(uint256 amountOverlying, address recipient) internal override returns (uint256 amountUnderlying) {
        amountUnderlying = amountOverlying;
        address(UNDERLYING_TOKEN).safeTransfer(recipient, amountUnderlying);
    }

    function _balanceOf(address user) internal view override returns (uint256) {
        uint256 totalShares_ = totalShares();
        if (totalShares_ == 0) return 0;
        return sharesOf(user) * OVERLYING_TOKEN.balanceOf(address(this)) / totalShares_;
    }

    function _totalBalance() internal view override returns (uint256) {
        return OVERLYING_TOKEN.balanceOf(address(this));
    }

    /// @inheritdoc IVersioned
    function version() external pure virtual override returns (string memory) {
        return "1.0.0";
    }
}
