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
        address usdcAddress = vm.getDeployment("USDC");
        address vaultAddress = vm.getDeployment("Vault");
        USDC usdc = USDC(usdcAddress);
        Vault vault = Vault(vaultAddress);

        usdc.mint(admin, 1000000e6);
        usdc.approve(vaultAddress, 1000000e6);
        vault.deposit(1, 1000000e6);
        vault.mint(1, 1e18);
        vm.stopBroadcast();
    }
}
