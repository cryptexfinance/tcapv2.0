// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IPocket} from "./pockets/IPocket.sol";
import {IVersioned} from "./IVersioned.sol";
import {ITCAPV2, IERC20} from "./ITCAPV2.sol";
import {IPermit2, ISignatureTransfer} from "permit2/src/interfaces/IPermit2.sol";

/// @title Vault interface
/// @notice Vaults manage deposits of collateral and mint TCAP tokens
interface IVault is IAccessControl, IVersioned {
    /// @notice Emitted when a pocket is added
    event PocketAdded(uint88 pocketId, IPocket pocket);

    /// @notice Emitted when a pocket is disabled
    event PocketDisabled(uint88 pocketId);

    /// @notice Emitted when the interest rate is updated
    event InterestRateUpdated(uint16 fee);

    /// @notice Emitted when a deposit is made
    /// @param user The address of the user who made the deposit
    /// @param pocketId The ID of the pocket the deposit was made to
    /// @param collateralAmount The amount of collateral deposited
    /// @param shares The amount of shares minted by the pocket
    event Deposited(address indexed user, uint88 indexed pocketId, uint256 collateralAmount, uint256 shares);

    event Withdrawn(address indexed user, uint88 indexed pocketId, address indexed recipient, uint256 shares, uint256 amount);

    /// @notice Thrown when a user provides an invalid value
    error InvalidValue();

    /// @notice Thrown when a user tries to deposit to a pocket that is not enabled
    error PocketNotEnabled(uint88 pocketId);

    /// @notice Thrown when a user provides an invalid token with a permit signature
    error InvalidToken();

    /// @notice Adds a new pocket to the vault
    /// @param pocket The pocket to add
    /// @return pocketId The generated id of the pocket
    /// @dev Only callable by the admin
    function addPocket(IPocket pocket) external returns (uint88 pocketId);

    /// @notice Removes a pocket from the vault
    /// @param pocketId The id of the pocket to remove
    /// @dev Only callable by the admin
    function removePocket(uint88 pocketId) external;

    /// @notice Updates the interest rate of the vault
    /// @param fee The new interest rate
    /// @dev Only callable by the fee setter
    function updateInterestRate(uint16 fee) external;

    // TODO: separate mint and borrow
    function deposit(uint88 pocketId, uint256 collateralAmount) external returns (uint256 shares);

    function depositWithPermit(uint88 pocketId, uint256 collateralAmount, IPermit2.PermitTransferFrom memory permit, bytes calldata signature)
        external
        returns (uint256 shares);

    /// @return The TCAPV2 contract
    function TCAPV2() external view returns (ITCAPV2);

    /// @return The collateral token of the vault
    function COLLATERAL() external view returns (IERC20);
}
