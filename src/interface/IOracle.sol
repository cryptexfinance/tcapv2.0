//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title Oracle Interface
/// @notice Interface that needs to be implemented by all oracles
interface IOracle {
    /// @notice Should be thrown when the oracle is not valid
    error InvalidOracle();

    /// @notice Thrown when the oracle is stale
    error StaleOracle();

    /// @return the address of the asset this oracle is used for
    function asset() external view returns (address);

    /// @return the latest price of the asset
    /// @dev the returned price must have 18 decimals
    function latestPrice(bool checkStaleness) external view returns (uint256);
}
