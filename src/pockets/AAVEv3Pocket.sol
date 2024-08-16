// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IPocket, BasePocket} from "./BasePocket.sol";
import {IVersioned} from "../interface/IVersioned.sol";
import {IPool} from "@aave/interfaces/IPool.sol";
import {IAAVEv3Pocket} from "../interface/pockets/IAAVEv3Pocket.sol";

/// @title AAVE v3 Pocket
/// @notice The AAVE v3 Pocket deposits funds into AAVE v3 to earn interest
contract AAVEv3Pocket is BasePocket, IAAVEv3Pocket {
    IPool public immutable POOL;

    constructor(address vault_, address underlyingToken_, address overlyingToken_, address aavePool) BasePocket(vault_, underlyingToken_, overlyingToken_) {
        POOL = IPool(aavePool);
    }

    /// @dev deposits underlying token into AAVE v3, aTokens are deposited into this pocket
    function _onDeposit(uint256 amountUnderlying) internal override returns (uint256 amountOverlying) {
        UNDERLYING_TOKEN.approve(address(POOL), amountUnderlying);
        POOL.deposit(address(UNDERLYING_TOKEN), amountUnderlying, address(this), 0);
        return amountUnderlying;
    }

    /// @dev redeems aTokens with AAVE v3, underlying token is returned to user
    function _onWithdraw(uint256 amountOverlying, address recipient) internal override returns (uint256 amountUnderlying) {
        if (amountOverlying == 0) return 0;
        POOL.withdraw(address(UNDERLYING_TOKEN), amountOverlying, recipient);
        return amountOverlying;
    }

    function _balanceOf(address user) internal view override returns (uint256) {
        return sharesOf(user) * OVERLYING_TOKEN.balanceOf(address(this)) / totalShares();
    }

    function _totalBalance() internal view override returns (uint256) {
        return OVERLYING_TOKEN.balanceOf(address(this));
    }

    /// @inheritdoc IVersioned
    function version() external pure override(BasePocket, IVersioned) returns (string memory) {
        return "1.0.0";
    }
}
