// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {Vm} from "forge-std/Vm.sol";

import "src/pockets/DefaultPocket.sol";
import "src/Vault.sol";
import {TCAPTargetOracle} from "src/oracle/TCAPTargetOracle.sol";
import {AggregatorV3Interface} from "@chainlink/interfaces/feeds/AggregatorV3Interface.sol";
import {Roles} from "src/lib/Constants.sol";
import {TCAPV2, ITCAPV2} from "src/TCAPV2.sol";
import {AggregatorInterfaceTCAP} from "script/mocks/AggregateInterfaceTCAP.sol";
import "script/mocks/USDC.sol";

contract MintTCAP is Script {

    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        address admin = vm.addr(vm.envUint("PRIVATE_KEY"));
        address usdcAddress = 0x94a9D9AC8a22534E3FaCa9F4e7F2E2cf85d5E4C8;
        address vaultAddress = vm.getDeployment("Vault");
        USDC usdc = USDC(usdcAddress);
        Vault vault = Vault(vaultAddress);
        usdc.approve(vaultAddress, 1000000e6);
        bytes[] memory payload = new bytes[](2);
        payload[0] = abi.encodeWithSelector(
            vault.deposit.selector,
            2,
            1000e6
        );
        payload[1] = abi.encodeWithSelector(
            vault.mint.selector,
            2,
            1e18
        );
        vault.multicall(payload);
        vm.stopBroadcast();
    }
}
