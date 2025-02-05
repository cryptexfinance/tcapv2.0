// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IVersioned {
    /// @return The version of the contract
    function version() external pure returns (string memory);
}
