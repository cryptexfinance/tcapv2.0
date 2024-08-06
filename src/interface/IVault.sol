// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IPocket} from "./pockets/IPocket.sol";
import {IVersioned} from "./IVersioned.sol";
import {ITCAPV2, IERC20} from "./ITCAPV2.sol";
import {IMulticall} from "./IMulticall.sol";
import {IPermit2, ISignatureTransfer} from "permit2/src/interfaces/IPermit2.sol";

/// @title Vault interface
/// @notice Vaults manage deposits of collateral and mint TCAP tokens
interface IVault is IAccessControl, IMulticall, IVersioned {
    /// @notice Emitted when a pocket is added
    event PocketAdded(uint88 pocketId, IPocket pocket);

    /// @notice Emitted when a pocket is disabled
    event PocketDisabled(uint88 pocketId);

    /// @notice Emitted when the interest rate is updated
    event InterestRateUpdated(uint16 fee);

    /// @notice Emitted when the oracle is updated
    /// @param newOracle The new oracle address
    event OracleUpdated(address indexed newOracle);

    /// @notice Emitted when the fee recipient is updated
    /// @param newFeeRecipient The new fee recipient address
    event FeeRecipientUpdated(address indexed newFeeRecipient);

    /// @notice Emitted when the liquidation threshold is updated
    /// @param newLiquidationThreshold The new liquidation threshold
    event LiquidationThresholdUpdated(uint256 newLiquidationThreshold);

    /// @notice Emitted when a deposit of collateral is made
    /// @param user The address of the user who made the deposit
    /// @param pocketId The id of the pocket the deposit was made to
    /// @param collateralAmount The amount of collateral deposited
    /// @param shares The amount of shares minted by the pocket
    event Deposited(address indexed user, uint88 indexed pocketId, uint256 collateralAmount, uint256 shares);

    /// @notice Emitted when a withdrawal of collateral is made
    /// @param user The address of the user who made the withdrawal
    /// @param pocketId The id of the pocket the withdrawal was made from
    /// @param recipient The address of the recipient of the withdrawal
    /// @param amount The amount of collateral withdrawn
    /// @param shares The amount of shares burned
    event Withdrawn(address indexed user, uint88 indexed pocketId, address indexed recipient, uint256 amount, uint256 shares);

    /// @notice Emitted when TCAP tokens are minted
    /// @param user The address of the user who minted the tokens
    /// @param pocketId The id of the pocket where the collateral is stored
    /// @param amount The amount of TCAP tokens minted
    event Minted(address indexed user, uint88 indexed pocketId, uint256 amount);

    /// @notice Emitted when TCAP tokens are burned
    /// @param user The address of the user who burned the tokens
    /// @param pocketId The id of the pocket where the collateral is stored
    /// @param amount The amount of TCAP tokens burned
    event Burned(address indexed user, uint88 indexed pocketId, uint256 amount);

    /// @notice Emitted when a loan of TCAP tokens is liquidated
    /// @param liquidator The address of the liquidator
    /// @param user The address of the user who was liquidated
    /// @param pocketId The id of the pocket where the collateral is stored
    /// @param collateralAmount The amount of collateral liquidated
    /// @param mintAmount The amount of TCAP tokens liquidated
    event Liquidated(address indexed liquidator, address indexed user, uint88 indexed pocketId, uint256 collateralAmount, uint256 mintAmount);

    /// @notice Thrown when a user provides an invalid value
    error InvalidValue();

    /// @notice Thrown when a user tries to deposit to a pocket that is not enabled
    error PocketNotEnabled(uint88 pocketId);

    /// @notice Thrown when a user provides an invalid token with a permit signature
    error InvalidToken();

    /// @notice Thrown when a user mints or withdraws and the loan falls below the liquidation threshold
    error LoanNotHealthy();

    /// @notice Thrown when a user is liquidated but the loan is still healthy
    error LoanHealthy();

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

    /// @notice Updates the fee recipient of the vault
    /// @param newFeeRecipient The new fee recipient address
    /// @dev Only callable by the fee setter
    function updateFeeRecipient(address newFeeRecipient) external;

    /// @notice Updates the oracle of the collateral
    /// @param newOracle The new oracle address
    /// @dev Only callable by the oracle setter
    function setOracle(address newOracle) external;

    /// @notice Updates the liquidation threshold of the vault
    /// @param newLiquidationThreshold The new liquidation threshold
    /// @dev Only callable by the admin
    function setLiquidationThreshold(uint256 newLiquidationThreshold) external;

    /// @notice Deposits collateral into a pocket
    /// @param pocketId The id of the pocket to deposit to
    /// @param collateralAmount The amount of collateral to deposit
    /// @return shares The amount of shares minted by the pocket
    function deposit(uint88 pocketId, uint256 collateralAmount) external returns (uint256 shares);

    /// @notice Deposits collateral into a pocket using a permit2 signature transfer
    /// @param pocketId The id of the pocket to deposit to
    /// @param collateralAmount The amount of collateral to deposit
    /// @param permit The permit data
    /// @param signature The signature
    /// @return shares The amount of shares minted by the pocket
    function depositWithPermit(uint88 pocketId, uint256 collateralAmount, IPermit2.PermitTransferFrom memory permit, bytes calldata signature)
        external
        returns (uint256 shares);

    /// @notice Withdraws collateral from a pocket
    /// @param pocketId The id of the pocket to withdraw from
    /// @param amount The amount of collateral to withdraw
    /// @param to The address to withdraw the collateral to
    /// @return shares The amount of shares burned
    /// @dev Takes the accrued fees from the user
    /// @dev Throws if the loan is not healthy after withdrawing
    function withdraw(uint88 pocketId, uint256 amount, address to) external returns (uint256 shares);

    /// @notice Mints TCAP tokens
    /// @param pocketId The id of the pocket where the collateral is stored
    /// @param amount The amount of TCAP tokens to mint
    /// @dev Throws if the loan is not healthy after minting
    function mint(uint88 pocketId, uint256 amount) external;

    /// @notice Burns TCAP tokens
    /// @param pocketId The id of the pocket where the collateral is stored
    /// @param amount The amount of TCAP tokens to burn
    function burn(uint88 pocketId, uint256 amount) external;

    /// @notice Liquidates a user's loan
    /// @param user The address of the user to liquidate
    /// @param pocketId The id of the pocket where the collateral is stored
    /// @dev Throws if the loan is not healthy
    function liquidate(address user, uint88 pocketId) external;

    /// @notice Returns the health factor of a user
    /// @param user The address of the user
    /// @param pocketId The id of the pocket
    /// @return The health factor of the user
    function healthFactor(address user, uint88 pocketId) external view returns (uint256);

    /// @notice Returns the value of `amount` of collateral tokens
    /// @param amount The amount of collateral
    /// @return The value of the collateral
    function collateralValueOf(uint256 amount) external view returns (uint256);

    /// @notice Returns the value of the collateral of a user
    /// @param user The address of the user
    /// @param pocketId The id of the pocket
    /// @return The value of the collateral of the user
    function collateralValueOfUser(address user, uint88 pocketId) external view returns (uint256);

    /// @notice Returns the value of `amount` of TCAP tokens
    /// @param amount The amount of TCAP tokens
    /// @return The value of the TCAP tokens
    function mintedValueOf(uint256 amount) external view returns (uint256);

    /// @notice Returns the value of minted TCAP tokens by a user
    /// @param user The address of the user
    /// @param pocketId The id of the pocket
    /// @return The value of the TCAP tokens of the user
    function mintedValueOfUser(address user, uint88 pocketId) external view returns (uint256);

    /// @notice Returns the amount of collateral of a user
    /// @param user The address of the user
    /// @param pocketId The id of the pocket
    /// @return The amount of collateral of the user
    function collateralOf(address user, uint88 pocketId) external view returns (uint256);

    /// @notice Returns the amount of TCAP tokens minted by a user
    /// @param user The address of the user
    /// @param pocketId The id of the pocket
    /// @return The amount of TCAP tokens minted by the user
    function mintedAmountOf(address user, uint88 pocketId) external view returns (uint256);

    /// @notice Returns the outstanding interest of a user denominated in the collateral
    /// @param user The address of the user
    /// @param pocketId The id of the pocket
    /// @return The outstanding interest of the user
    function outstandingInterestOf(address user, uint88 pocketId) external view returns (uint256);

    /// @return The latest price of the collateral
    function latestPrice() external view returns (uint256);

    /// @return The oracle of the collateral
    function oracle() external view returns (address);

    /// @return The current interest rate of the vault
    function interestRate() external view returns (uint16);

    /// @return The fee recipient of the vault
    function feeRecipient() external view returns (address);

    /// @return The liquidation threshold of the vault
    function liquidationThreshold() external view returns (uint256);

    /// @return The TCAPV2 contract
    function TCAPV2() external view returns (ITCAPV2);

    /// @return The collateral token of the vault
    function COLLATERAL() external view returns (IERC20);
}
