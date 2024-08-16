// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IOracle} from "../interface/IOracle.sol";

/// @title Base Oracle USD
/// @notice Base contract that sets the underlying asset and the decimals of that asset for the oracle
abstract contract BaseOracleUSD is IOracle {
    address public immutable asset;
    uint256 public immutable assetDecimals;

    constructor(address token) {
        asset = token;
        assetDecimals = IERC20Metadata(token).decimals();
    }
}
