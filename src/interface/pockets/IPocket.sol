// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {IVault} from "../../interface/IVault.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IVersioned} from "../../interface/IVersioned.sol";

/// @title Pocket Interface
/// @notice Base interface for all pockets
/// @notice A pocket is used to separate deposited funds based on their use case
interface IPocket is IVersioned {
    /// @notice Emitted when a user deposits underlying tokens into the pocket
    /// @param user The address of the user who deposited the underlying tokens
    /// @param amountUnderlying The amount of underlying tokens deposited
    /// @param amountOverlying The amount of overlying tokens added to the users balance
    /// @param shares The amount of shares received
    event Deposit(address indexed user, uint256 amountUnderlying, uint256 amountOverlying, uint256 shares);

    /// @notice Emitted when a user withdraws underlying tokens from the pocket
    /// @param user The address of the user who withdrew the underlying tokens
    /// @param recipient The address of the recipient who received the underlying tokens
    /// @param amountUnderlying The amount of underlying tokens withdrawn
    /// @param amountOverlying The amount of overlying tokens removed from the users balance
    /// @param shares The amount of shares burned
    event Withdrawal(address indexed user, address indexed recipient, uint256 amountUnderlying, uint256 amountOverlying, uint256 shares);

    /// @notice Emitted when an account that is not the vault calls a restricted function
    error Unauthorized();

    /// @notice Thrown when a user tries to burn more shares than they own
    error InsufficientFunds();

    /// @notice called by the vault to deposit underlying tokens into the pocket
    /// @param user The address of the user who deposits the underlying tokens
    /// @param amountUnderlying The amount of underlying tokens deposited
    /// @return shares The amount of shares received
    /// @dev requires `amountUnderlying` amount of underlying tokens to be deposited into the contract before calling this function
    /// @dev Only callable by the vault
    function registerDeposit(address user, uint256 amountUnderlying) external returns (uint256 shares);

    /// @notice called by the vault to withdraw underlying tokens from the pocket
    /// @param user The address of the user who withdraws the underlying tokens
    /// @param shares The amount of shares burned
    /// @param recipient The address of the recipient who receives the underlying tokens
    /// @return amountUnderlying The amount of underlying tokens withdrawn
    /// @dev Only callable by the vault
    /// @dev MUST revert if more shares are withdrawn than shares owned by user
    function withdraw(address user, uint256 shares, address recipient) external returns (uint256 amountUnderlying);

    /// @return vault The vault that the pocket is registered to
    function VAULT() external view returns (IVault);

    /// @return underlyingToken The underlying token of the pocket, e.g. WETH
    function UNDERLYING_TOKEN() external view returns (IERC20);

    /// @return overlyingToken The overlying token of the pocket
    /// @dev the overlying token can be an Aave aToken (e.g., aWETH), it can also be equal to the underlying token
    function OVERLYING_TOKEN() external view returns (IERC20);

    /// @return totalShares The total amount of shares issued by the pocket
    function totalShares() external view returns (uint256);

    /// @return shares The amount of shares owned by the user
    function sharesOf(address user) external view returns (uint256 shares);

    /// @return amount The underlying balance of the contract
    function totalBalance() external view returns (uint256 amount);

    /// @return amount The underlying balance of the user
    function balanceOf(address user) external view returns (uint256 amount);
}
