// SPDX-License-Identifier: MIT
/** @notice this contract is for tests only */

pragma solidity ^0.8.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract USDC is ERC20 {
  constructor() ERC20("Mockup USDC", "mUSDC") {}

  function mint(address _account, uint256 _amount) public {
    _mint(_account, _amount);
  }

  function burn(address _account, uint256 _amount) public {
    _burn(_account, _amount);
  }

  function decimals() public pure override returns (uint8) {
    return 8;
  }
}
