// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IVersioned} from "./IVersioned.sol";

interface IVault is IAccessControl, IVersioned {
    event PocketAdded(uint88 pocketId, address pocket);
    event PocketDisabled(uint88 pocketId);
    event InterestRateUpdated(uint16 fee);
    event Deposited(address indexed user, uint88 indexed pocketId, uint256 indexed depositId, uint256 mintAmount, uint256 collateralAmount);

    error InvalidValue();
    error DepositIdAlreadyUsed(uint256 depositId);
    error PocketNotEnabled(uint88 pocketId);

    function addPocket(address pocket) external returns (uint88 pocketId);
}
