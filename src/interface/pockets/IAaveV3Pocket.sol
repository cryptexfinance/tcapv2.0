// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {IPocket} from "./IPocket.sol";
import {IPool} from "@aave/interfaces/IPool.sol";

/// @title Aave v3 Pocket Interface
/// @notice Interface for pockets depositing underlying tokens into Aave v3
interface IAaveV3Pocket is IPocket {
    /// @return pool Aave v3 Pool
    function POOL() external view returns (IPool pool);
}
