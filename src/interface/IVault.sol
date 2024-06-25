// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IVersioned} from "./IVersioned.sol";

interface IVault is IAccessControl, IVersioned {
    event PocketAdded(uint256 pocketId, address pocket);

    function addPocket(address pocket) external returns (uint256 pocketId);
}
