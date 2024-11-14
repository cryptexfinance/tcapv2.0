// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {Vm} from "forge-std/Vm.sol";

import {USDCDeployer} from "script/deployers/USDCDeployer.s.sol";
import {TCAPV2Deployer} from "script/deployers/TCAPV2Deployer.s.sol";
import {USDCOracleDeployer} from "script/deployers/USDCOracleDeployer.s.sol";
import {TCAPOracleDeployer} from "script/deployers/TCAPOracleDeployer.s.sol";
import {VaultDeployer} from "script/deployers/VaultDeployer.s.sol";
import {DefaultPocketDeployer} from "script/deployers/DefaultPocketDeployer.s.sol";
import {SetupSystem} from "script/deployers/SetupSystem.s.sol";

contract DeployToTestNet is
    USDCDeployer,
    TCAPV2Deployer,
    USDCOracleDeployer,
    TCAPOracleDeployer,
    VaultDeployer,
    DefaultPocketDeployer,
    SetupSystem {

    function run() external {
        deployUSDC();
        deployTCAPV2Implementation();
        deployUSDCOracle();
        deployTCAPOracle();
        deployVault();
        deployDefaultPocket();
        setupSystem();
    }
}
