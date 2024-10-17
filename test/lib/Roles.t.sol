// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import "test/util/TestHelpers.sol";
import "../../script/deployers/TCAPV2Deployer.s.sol";
import "../../script/deployers/VaultDeployer.s.sol";
import {Roles} from "../../src/lib/Constants.sol";
import {MockCollateral} from "../mock/MockCollateral.sol";

contract RolesTest is Test, TestHelpers, VaultDeployer, TCAPV2Deployer {
    function setUp() public {
        tCAPV2 = TCAPV2(deployTCAPV2Implementation());
        vault = Vault(deployVaultImplementation(tCAPV2, new MockCollateral(), IPermit2(makeAddr("permit2"))));
    }

    function test_ShouldComputeCorrectRole() public {
        assertEq(Roles.DEFAULT_ADMIN_ROLE, bytes32(0));
        assertEq(Roles.VAULT_ROLE, keccak256("VAULT_ROLE"));
        assertEq(Roles.ORACLE_SETTER_ROLE, keccak256("ORACLE_SETTER_ROLE"));
        assertEq(Roles.POCKET_SETTER_ROLE, keccak256("POCKET_SETTER_ROLE"));
        assertEq(Roles.FEE_SETTER_ROLE, keccak256("FEE_SETTER_ROLE"));
        assertEq(Roles.FEE_COLLECTOR_ROLE, keccak256("FEE_COLLECTOR_ROLE"));
        assertEq(Roles.LIQUIDATION_SETTER_ROLE, keccak256("LIQUIDATION_SETTER_ROLE"));
    }
}
