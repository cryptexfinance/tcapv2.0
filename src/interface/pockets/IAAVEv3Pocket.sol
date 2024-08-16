// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {IPocket} from "./IPocket.sol";
import {IPool} from "@aave/interfaces/IPool.sol";

/// @title AAVE v3 Pocket Interface
/// @notice Interface for pockets depositing underlying tokens into AAVE v3
interface IAAVEv3Pocket is IPocket {
    /// @return pool AAVE v3 Pool
    function POOL() external view returns (IPool pool);
}
