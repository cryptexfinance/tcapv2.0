// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IPocket} from "./pockets/IPocket.sol";
import {IVersioned} from "./IVersioned.sol";
import {ITCAPV2, IERC20} from "./ITCAPV2.sol";
import {IMulticall} from "./IMulticall.sol";
import {IPermit2, ISignatureTransfer} from "permit2/src/interfaces/IPermit2.sol";

/// @title Vault interface
/// @notice Vaults manage deposits of collateral and mint TCAP tokens
interface IVault is IAccessControl, IMulticall, IVersioned {
    /// @notice Liquidation params of the vault
    /// @param threshold The liquidation threshold
    /// @param penalty The liquidation penalty
    /// @param minHealthFactor The minimum health factor after liquidation added to the liquidation threshold
    /// @param maxHealthFactor The maximum health factor after liquidation added to the liquidation threshold
    /// @dev after liquidation the health factor must be liquidationThreshold + minHealthFactor < x < liquidationThreshold + maxHealthFactor
    /// @dev e.g., liquidationThreshold + 10% < x < liquidationThreshold + 30%
    struct LiquidationParams {
        uint64 threshold;
        uint64 penalty;
        uint64 minHealthFactor;
        uint64 maxHealthFactor;
    }

    /// @notice Emitted when a pocket is added
    event PocketAdded(uint96 pocketId, IPocket pocket);

    /// @notice Emitted when a pocket is disabled
    event PocketDisabled(uint96 pocketId);

    /// @notice Emitted when the interest rate is updated
    event InterestRateUpdated(uint16 fee);

    /// @notice Emitted when the oracle is updated
    /// @param newOracle The new oracle address
    event OracleUpdated(address indexed newOracle);

    /// @notice Emitted when the fee recipient is updated
    /// @param newFeeRecipient The new fee recipient address
    event FeeRecipientUpdated(address indexed newFeeRecipient);

    /// @notice Emitted when the liquidation params are updated
    /// @param newLiquidationParams The new liquidation params
    event LiquidationParamsUpdated(LiquidationParams newLiquidationParams);

    /// @notice Emitted when a deposit of collateral is made
    /// @param user The address of the user who made the deposit
    /// @param pocketId The id of the pocket the deposit was made to
    /// @param collateralAmount The amount of collateral deposited
    /// @param shares The amount of shares minted by the pocket
    event Deposited(address indexed user, uint96 indexed pocketId, uint256 collateralAmount, uint256 shares);

    /// @notice Emitted when a withdrawal of collateral is made
    /// @param user The address of the user who made the withdrawal
    /// @param pocketId The id of the pocket the withdrawal was made from
    /// @param recipient The address of the recipient of the withdrawal
    /// @param amount The amount of collateral withdrawn
    /// @param shares The amount of shares burned
    event Withdrawn(address indexed user, uint96 indexed pocketId, address indexed recipient, uint256 amount, uint256 shares);

    /// @notice Emitted when TCAP tokens are minted
    /// @param user The address of the user who minted the tokens
    /// @param pocketId The id of the pocket where the collateral is stored
    /// @param amount The amount of TCAP tokens minted
    event Minted(address indexed user, uint96 indexed pocketId, uint256 amount);

    /// @notice Emitted when TCAP tokens are burned
    /// @param user The address of the user who burned the tokens
    /// @param pocketId The id of the pocket where the collateral is stored
    /// @param amount The amount of TCAP tokens burned
    event Burned(address indexed user, uint96 indexed pocketId, uint256 amount);

    /// @notice Emitted when a loan of TCAP tokens is liquidated
    /// @param liquidator The address of the liquidator
    /// @param user The address of the user who was liquidated
    /// @param pocketId The id of the pocket where the collateral is stored
    /// @param collateralAmount The amount of collateral liquidated
    /// @param mintAmount The amount of TCAP tokens liquidated
    event Liquidated(address indexed liquidator, address indexed user, uint96 indexed pocketId, uint256 collateralAmount, uint256 mintAmount);

    /// @notice Emitted when a fee is collected from a user
    /// @param user The address of the user who paid the fee
    /// @param pocketId The id of the pocket where the collateral is stored
    /// @param feeRecipient The address of the fee recipient
    /// @param amount The amount of fee collected
    event FeeCollected(address indexed user, uint96 indexed pocketId, address indexed feeRecipient, uint256 amount);

    enum ErrorCode {
        ZERO_VALUE, // 0
        INVALID_POCKET, // 1
        INVALID_POCKET_COLLATERAL, // 2
        MAX_FEE, // 3
        MAX_LIQUIDATION_PENALTY, // 4
        MAX_LIQUIDATION_THRESHOLD, // 5
        MIN_LIQUIDATION_THRESHOLD, // 6
        MAX_POST_LIQUIDATION_HEALTH_FACTOR, // 7
        MIN_POST_LIQUIDATION_HEALTH_FACTOR, // 8
        INCOMPATIBLE_MAX_POST_LIQUIDATION_HEALTH_FACTOR, // 9
        INVALID_BURN_AMOUNT, // 10
        MUST_LIQUIDATE_ENTIRE_POSITION, // 11
        HEALTH_FACTOR_BELOW_MINIMUM, // 12
        HEALTH_FACTOR_ABOVE_MAXIMUM // 13

    }

    /// @notice Thrown when a user provides an invalid value
    /// @param code The identifier of the error
    error InvalidValue(ErrorCode code);

    /// @notice Thrown when a user tries to deposit to a pocket that is not enabled
    error PocketNotEnabled(uint96 pocketId);

    /// @notice Thrown when a user provides an invalid token with a permit signature
    error InvalidToken();

    /// @notice Thrown when a user tries to burn more TCAP tokens than they have minted using this vault
    error InsufficientMintedAmount();

    /// @notice Thrown when a user mints or withdraws and the loan falls below the liquidation threshold
    error LoanNotHealthy();

    /// @notice Thrown when a user is liquidated but the loan is still healthy
    error LoanHealthy();

    /// @notice Adds a new pocket to the vault
    /// @param pocket The pocket to add
    /// @return pocketId The generated id of the pocket
    /// @dev Only callable by the admin
    function addPocket(IPocket pocket) external returns (uint96 pocketId);

    /// @notice Disables a pocket to be used for deposits
    /// @param pocketId The id of the pocket to disable
    /// @dev Only callable by the admin
    function disablePocket(uint96 pocketId) external;

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
    function updateOracle(address newOracle) external;

    /// @notice Updates the liquidation params of the vault
    /// @param newLiquidationParams The new liquidation params
    /// @dev Only callable by the admin
    function updateLiquidationParams(LiquidationParams calldata newLiquidationParams) external;

    /// @notice Deposits collateral into a pocket
    /// @param pocketId The id of the pocket to deposit to
    /// @param collateralAmount The amount of collateral to deposit
    /// @return shares The amount of shares minted by the pocket
    function deposit(uint96 pocketId, uint256 collateralAmount) external returns (uint256 shares);

    /// @notice Deposits collateral into a pocket using a permit2 signature transfer
    /// @param pocketId The id of the pocket to deposit to
    /// @param collateralAmount The amount of collateral to deposit
    /// @param permit The permit data
    /// @param signature The signature
    /// @return shares The amount of shares minted by the pocket
    function depositWithPermit(uint96 pocketId, uint256 collateralAmount, IPermit2.PermitTransferFrom calldata permit, bytes calldata signature)
        external
        returns (uint256 shares);

    /// @notice Withdraws collateral from a pocket
    /// @param pocketId The id of the pocket to withdraw from
    /// @param amount The amount of collateral to withdraw
    /// @param to The address to withdraw the collateral to
    /// @return shares The amount of shares burned
    /// @dev Takes the accrued fees from the user
    /// @dev Throws if the loan is not healthy after withdrawing
    function withdraw(uint96 pocketId, uint256 amount, address to) external returns (uint256 shares);

    /// @notice Mints TCAP tokens
    /// @param pocketId The id of the pocket where the collateral is stored
    /// @param amount The amount of TCAP tokens to mint
    /// @dev Throws if the loan is not healthy after minting
    function mint(uint96 pocketId, uint256 amount) external;

    /// @notice Burns TCAP tokens
    /// @param pocketId The id of the pocket where the collateral is stored
    /// @param amount The amount of TCAP tokens to burn
    function burn(uint96 pocketId, uint256 amount) external;

    /// @notice Liquidates a user's loan
    /// @param user The address of the user to liquidate
    /// @param pocketId The id of the pocket where the collateral is stored
    /// @param burnAmount The amount of TCAP tokens to burn
    /// @return liquidationReward The amount of collateral liquidated and returned to the liquidator
    /// @dev Throws if the loan is not healthy
    /// @dev after the liquidation the health factor must be between the minimum and maximum bounds of the liquidation params
    function liquidate(address user, uint96 pocketId, uint256 burnAmount) external returns (uint256 liquidationReward);

    /// @notice Takes the accrued fees from a user and sends them to the fee recipient
    /// @param user The address of the user to take the fees from
    /// @param pocketId The id of the pocket where the collateral is stored
    /// @dev Only callable by the fee setter
    function takeFee(address user, uint96 pocketId) external;

    /// @notice Returns the health factor of a user
    /// @param user The address of the user
    /// @param pocketId The id of the pocket
    /// @return The health factor of the user
    function healthFactor(address user, uint96 pocketId) external view returns (uint256);

    /// @notice Returns the value of `amount` of collateral tokens
    /// @param amount The amount of collateral
    /// @return The value of the collateral
    function collateralValueOf(uint256 amount) external view returns (uint256);

    /// @notice Returns the value of the collateral of a user
    /// @param user The address of the user
    /// @param pocketId The id of the pocket
    /// @return The value of the collateral of the user
    function collateralValueOfUser(address user, uint96 pocketId) external view returns (uint256);

    /// @notice Returns the value of `amount` of TCAP tokens
    /// @param amount The amount of TCAP tokens
    /// @return The value of the TCAP tokens
    function mintedValueOf(uint256 amount) external view returns (uint256);

    /// @notice Returns the value of minted TCAP tokens by a user
    /// @param user The address of the user
    /// @param pocketId The id of the pocket
    /// @return The value of the TCAP tokens of the user
    function mintedValueOfUser(address user, uint96 pocketId) external view returns (uint256);

    /// @notice Returns the amount of collateral of a user
    /// @param user The address of the user
    /// @param pocketId The id of the pocket
    /// @return The amount of collateral of the user
    function collateralOf(address user, uint96 pocketId) external view returns (uint256);

    /// @notice Returns the amount of TCAP tokens minted by a user
    /// @param user The address of the user
    /// @param pocketId The id of the pocket
    /// @return The amount of TCAP tokens minted by the user
    function mintedAmountOf(address user, uint96 pocketId) external view returns (uint256);

    /// @notice Returns the outstanding interest of a user denominated in the collateral
    /// @param user The address of the user
    /// @param pocketId The id of the pocket
    /// @return The outstanding interest of the user
    function outstandingInterestOf(address user, uint96 pocketId) external view returns (uint256);

    /// @return The latest price of the collateral
    function latestPrice() external view returns (uint256);

    /// @return The oracle of the collateral
    function oracle() external view returns (address);

    /// @return The current interest rate of the vault
    function interestRate() external view returns (uint16);

    /// @return The fee recipient of the vault
    function feeRecipient() external view returns (address);

    /// @return The liquidation params of the vault
    function liquidationParams() external view returns (LiquidationParams memory);

    /// @return The TCAPV2 contract
    function TCAPV2() external view returns (ITCAPV2);

    /// @return The collateral token of the vault
    function COLLATERAL() external view returns (IERC20);

    /// @return The pocket with the given id
    function pockets(uint96 id) external view returns (IPocket);

    /// @return Whether the pocket with the given id is enabled
    function pocketEnabled(uint96 id) external view returns (bool);
}
