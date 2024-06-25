// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IVersioned} from "./IVersioned.sol";

interface ITCAPV2 is IERC20, IAccessControl, IVersioned {
    event Minted(address indexed vault, address indexed recipient, uint256 amount);
    event Burned(address indexed vault, address indexed recipient, uint256 amount);

    error BalanceExceeded(address vault);

    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
    function mintedAmount(address vault) external view returns (uint256);
}
