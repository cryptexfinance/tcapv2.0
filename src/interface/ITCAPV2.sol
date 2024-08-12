// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IVersioned} from "./IVersioned.sol";

/// @title TCAP v2
/// @notice TCAP v2 is an index token that is pegged to the entire crypto market cap
interface ITCAPV2 is IERC20, IAccessControl, IVersioned {
    /// @notice Emitted when a vault mints TCAP tokens
    event Minted(address indexed vault, address indexed recipient, uint256 amount);

    /// @notice Emitted when a vault burns TCAP tokens
    event Burned(address indexed vault, address indexed recipient, uint256 amount);

    /// @notice Emitted when the oracle is updated
    /// @param newOracle The new oracle address
    event OracleUpdated(address indexed newOracle);

    /// @notice Thrown when a vault tries to burn more TCAP tokens than it has minted
    error BalanceExceeded(address vault);

    /// @notice Mints new TCAP tokens
    /// @param to The address to mint the tokens to
    /// @param amount The amount of tokens to mint
    /// @dev Only callable by registered vaults
    function mint(address to, uint256 amount) external;

    /// @notice Burns TCAP tokens
    /// @param from The address to burn the tokens from
    /// @param amount The amount of tokens to burn
    /// @dev Only callable by registered vaults
    function burn(address from, uint256 amount) external;

    /// @notice Sets the new oracle for the crypto marketcap
    /// @param newOracle The new oracle address
    /// @dev Only callable by the oracle setter
    function setOracle(address newOracle) external;

    /// @notice Returns the amount of TCAP tokens minted by a vault
    function mintedAmount(address vault) external view returns (uint256);

    /// @return The oracle of the crypto marketcap
    function oracle() external view returns (address);

    /// @return The target price of the TCAP token
    /// @dev Defined as the value of the total crypto marketcap divided by the divisor
    function latestPrice() external view returns (uint256);

    /// @return Value used as divisor with the total market cap, just like the S&P 500 or any major financial index would to define the final tcap token price
    function DIVISOR() external view returns (uint256);
}
