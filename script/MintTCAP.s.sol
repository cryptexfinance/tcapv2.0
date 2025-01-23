// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {Vm} from "forge-std/Vm.sol";

import "src/pockets/DefaultPocket.sol";
import "src/Vault.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {TCAPTargetOracle} from "src/oracle/TCAPTargetOracle.sol";
import {AggregatorV3Interface} from "@chainlink/interfaces/feeds/AggregatorV3Interface.sol";
import {Roles} from "src/lib/Constants.sol";
import {TCAPV2, ITCAPV2} from "src/TCAPV2.sol";

contract MintTCAP is Script {

    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        address admin = vm.addr(vm.envUint("PRIVATE_KEY"));
        address usdcAddress = 0x036CbD53842c5426634e7929541eC2318f3dCF7e;
        address vaultAddress = 0x62beb4f28f70cF7E4d5BCa54e86851b12AeF2d48;
        IERC20 usdc = IERC20(usdcAddress);
        Vault vault = Vault(vaultAddress);
        usdc.approve(vaultAddress, 1000000e6);
        bytes[] memory payload = new bytes[](2);
        payload[0] = abi.encodeWithSelector(
            vault.deposit.selector,
            2,
            5e6
        );
        payload[1] = abi.encodeWithSelector(
            vault.mint.selector,
            2,
            1e15
        );
        vault.multicall(payload);
        vm.stopBroadcast();
    }
}
