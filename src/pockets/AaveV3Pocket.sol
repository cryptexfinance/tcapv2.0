// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BasePocket} from "./BasePocket.sol";
import {IVersioned} from "../interface/IVersioned.sol";
import {IPool} from "@aave/interfaces/IPool.sol";
import {IAaveV3Pocket} from "../interface/pockets/IAaveV3Pocket.sol";

/// @title Aave v3 Pocket
/// @notice The Aave v3 Pocket deposits funds into Aave v3 to earn interest
contract AaveV3Pocket is BasePocket, IAaveV3Pocket {
    IPool public immutable POOL;

    constructor(address vault_, address underlyingToken_, address aavePool)
        BasePocket(vault_, underlyingToken_, IPool(aavePool).getReserveData(underlyingToken_).aTokenAddress)
    {
        POOL = IPool(aavePool);
        require(address(OVERLYING_TOKEN) != address(0));
    }

    function initialize() public {
        UNDERLYING_TOKEN.approve(address(POOL), type(uint256).max);
    }

    /// @dev deposits underlying token into Aave v3, aTokens are deposited into this pocket
    function _onDeposit(uint256 amountUnderlying) internal override returns (uint256 amountOverlying) {
        POOL.supply(address(UNDERLYING_TOKEN), amountUnderlying, address(this), 0);
        return amountUnderlying;
    }

    /// @dev redeems aTokens with Aave v3, underlying token is returned to user
    function _onWithdraw(uint256 amountOverlying, address recipient) internal override returns (uint256 amountUnderlying) {
        if (amountOverlying == 0) return 0;
        uint256 amountWithdrawn = POOL.withdraw(address(UNDERLYING_TOKEN), amountOverlying, recipient);
        // https://github.com/code-423n4/2022-06-connext-findings/issues/181
        assert(amountWithdrawn == amountOverlying);
        return amountOverlying;
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
    function version() external pure override(BasePocket, IVersioned) returns (string memory) {
        return "1.0.0";
    }
}
