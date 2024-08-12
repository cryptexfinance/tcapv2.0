// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "test/util/TestHelpers.sol";

import "script/deployers/TCAPV2Deployer.s.sol";
import "script/deployers/VaultDeployer.s.sol";

import {MockFeed} from "./mock/MockFeed.sol";
import {AggregatedChainlinkOracle} from "../src/oracle/AggregatedChainlinkOracle.sol";
import {TCAPTargetOracle} from "../src/oracle/TCAPTargetOracle.sol";
import {MockCollateral} from "./mock/MockCollateral.sol";
import {Deploy, IPermit2} from "./util/Deploy.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {BasePocket} from "../src/pockets/BasePocket.sol";
import {Constants} from "../src/lib/Constants.sol";

abstract contract Initialized is Test, TestHelpers, VaultDeployer, TCAPV2Deployer {
    MockCollateral collateral;
    address admin = address(this);
    IPermit2 permit2;

    MockFeed feedTCAP;
    TCAPTargetOracle oracleTCAP;

    MockFeed feed;
    AggregatedChainlinkOracle oracle;

    address feeRecipient = makeAddr("feeRecipient");

    function setUp() public virtual {
        collateral = new MockCollateral();
        permit2 = Deploy.permit2();
        deployTCAPV2Transparent(admin, admin);
        tCAPV2.grantRole(tCAPV2.ORACLE_SETTER_ROLE(), admin);
        tCAPV2.grantRole(tCAPV2.VAULT_ROLE(), admin);
        feedTCAP = new MockFeed(3e12 * 1e8);
        oracleTCAP = new TCAPTargetOracle(tCAPV2, address(feedTCAP));
        tCAPV2.setOracle(address(oracleTCAP));

        feed = new MockFeed(3000 ether);
        oracle = new AggregatedChainlinkOracle(address(feed), address(collateral));

        deployVaultTransparent({
            proxyAdminOwner: admin,
            tCAPV2_: tCAPV2,
            collateral_: collateral,
            permit2_: permit2,
            admin: admin,
            initialFee: 0,
            oracle_: address(oracle),
            feeRecipient_: feeRecipient,
            liquidationThreshold_: 1 ether
        });
    }
}

abstract contract Permitted is Initialized {
    function setUp() public virtual override {
        super.setUp();
        vault.grantRole(vault.POCKET_SETTER_ROLE(), admin);
        vault.grantRole(vault.FEE_SETTER_ROLE(), admin);
        vault.grantRole(vault.ORACLE_SETTER_ROLE(), admin);
        vault.grantRole(vault.LIQUIDATION_SETTER_ROLE(), admin);
    }
}

abstract contract PocketSetup is Permitted {
    address pocket;
    uint256 pocketId;

    function setUp() public virtual override {
        super.setUp();
        pocket = address(new BasePocket(address(vault), address(collateral), address(collateral)));
        pocketId = vault.addPocket(IPocket(pocket));
    }
}

contract UninitializedTest is Initialized {
    function test_RevertsOnInitialization() public {
        Vault vault_ = Vault(deployVaultImplementation(tCAPV2, collateral, permit2));
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        vault_.initialize(makeAddr("admin"), 1, makeAddr("oracle"), makeAddr("feeRecipient"), 1);
    }

    function test_Version() public {
        Vault vault_ = Vault(deployVaultImplementation(tCAPV2, collateral, permit2));
        assertEq(vault_.version(), "1.0.0");
    }
}

contract PermissionsTest is Initialized {
    error AccessControlUnauthorizedAccount(address account, bytes32 role);

    function test_RevertIf_InvalidPermission_PocketSetter(address sender) public {
        vm.assume(sender != address(vaultProxyAdmin));
        vm.expectRevert(abi.encodeWithSelector(AccessControlUnauthorizedAccount.selector, sender, vault.POCKET_SETTER_ROLE()));
        vm.prank(sender);
        vault.addPocket(IPocket(makeAddr("pocket")));
        vm.expectRevert(abi.encodeWithSelector(AccessControlUnauthorizedAccount.selector, sender, vault.POCKET_SETTER_ROLE()));
        vm.prank(sender);
        vault.disablePocket(0);
    }

    function test_RevertIf_InvalidPermission_FeeSetter(address sender) public {
        vm.assume(sender != address(vaultProxyAdmin));
        vm.expectRevert(abi.encodeWithSelector(AccessControlUnauthorizedAccount.selector, sender, vault.FEE_SETTER_ROLE()));
        vm.prank(sender);
        vault.updateInterestRate(0);
        vm.expectRevert(abi.encodeWithSelector(AccessControlUnauthorizedAccount.selector, sender, vault.FEE_SETTER_ROLE()));
        vm.prank(sender);
        vault.updateFeeRecipient(feeRecipient);
    }

    function test_RevertIf_InvalidPermission_OracleSetter(address sender) public {
        vm.assume(sender != address(vaultProxyAdmin));
        vm.expectRevert(abi.encodeWithSelector(AccessControlUnauthorizedAccount.selector, sender, vault.ORACLE_SETTER_ROLE()));
        vm.prank(sender);
        vault.updateOracle(address(0));
    }

    function test_RevertIf_InvalidPermission_LiquidationSetter(address sender) public {
        vm.assume(sender != address(vaultProxyAdmin));
        vm.expectRevert(abi.encodeWithSelector(AccessControlUnauthorizedAccount.selector, sender, vault.LIQUIDATION_SETTER_ROLE()));
        vm.prank(sender);
        vault.updateLiquidationThreshold(1);
    }
}

contract ManagementTest is Permitted {
    function test_RevertIf_InterestRateOutOfBounds(uint16 interestRate) public {
        interestRate = uint16(bound(interestRate, FeeCalculatorLib.MAX_FEE + 1, type(uint16).max));
        vm.expectRevert(IVault.InvalidValue.selector);
        vault.updateInterestRate(interestRate);
    }

    function test_ShouldUpdateInterestRate(uint16 interestRate) public {
        interestRate = uint16(bound(interestRate, 1, FeeCalculatorLib.MAX_FEE));
        vm.expectEmit(true, true, false, true);
        emit IVault.InterestRateUpdated(interestRate);
        vault.updateInterestRate(interestRate);
        assertEq(vault.interestRate(), interestRate);
    }

    function test_ShouldUpdateFeeRecipient(address feeRecipient_) public {
        vm.expectEmit(true, true, false, true);
        emit IVault.FeeRecipientUpdated(feeRecipient_);
        vault.updateFeeRecipient(feeRecipient_);
        assertEq(vault.feeRecipient(), feeRecipient_);
    }

    function test_RevertIf_OracleIsNotForVaultCollateral() public {
        address oracle_ = tCAPV2.oracle();
        vm.expectRevert(IOracle.InvalidOracle.selector);
        vault.updateOracle(oracle_);
    }

    function test_ShouldUpdateOracle() public {
        vm.expectEmit(true, true, false, true);
        emit IVault.OracleUpdated(address(oracle));
        vault.updateOracle(address(oracle));
        assertEq(vault.oracle(), address(oracle));
    }

    function test_RevertIf_LiquidationThresholdOutOfBounds(uint96 liquidationThreshold) public {
        vm.assume(liquidationThreshold < Constants.MIN_LIQUIDATION_THRESHOLD || liquidationThreshold > Constants.MAX_LIQUIDATION_THRESHOLD);
        vm.expectRevert(IVault.InvalidValue.selector);
        vault.updateLiquidationThreshold(liquidationThreshold);
    }

    function test_ShouldUpdateLiquidationThreshold(uint96 liquidationThreshold) public {
        liquidationThreshold = uint96(bound(liquidationThreshold, Constants.MIN_LIQUIDATION_THRESHOLD, Constants.MAX_LIQUIDATION_THRESHOLD));
        vm.expectEmit(true, true, false, true);
        emit IVault.LiquidationThresholdUpdated(liquidationThreshold);
        vault.updateLiquidationThreshold(liquidationThreshold);
        assertEq(vault.liquidationThreshold(), liquidationThreshold);
    }
}

contract PocketTest is Permitted {
    function test_RevertIf_PocketIsZero() public {
        vm.expectRevert(IVault.InvalidValue.selector);
        vault.addPocket(IPocket(address(0)));
    }

    function test_RevertIf_PocketDoesNotHaveVaultFunction() public {
        vm.expectRevert();
        vault.addPocket(IPocket(makeAddr("pocket")));
    }

    function test_RevertIf_PocketDoesNotPointToVault() public {
        address pocket = address(new BasePocket(makeAddr("vault"), address(collateral), address(collateral)));
        vm.expectRevert(IVault.InvalidValue.selector);
        vault.addPocket(IPocket(pocket));
    }

    function test_RevertIf_PocketDoesNotHaveCorrectUnderlyingToken() public {
        address pocket = address(new BasePocket(address(vault), makeAddr("collateral"), makeAddr("collateral")));
        vm.expectRevert(IVault.InvalidValue.selector);
        vault.addPocket(IPocket(pocket));
    }

    function test_ShouldAddPocket() public {
        address basePocket = address(new BasePocket(address(vault), address(collateral), address(collateral)));
        uint256 pocketId = 1;
        vm.expectEmit(true, true, false, true);
        emit IVault.PocketAdded(uint88(pocketId), IPocket(basePocket));
        vault.addPocket(IPocket(basePocket));
        assertEq(address(vault.pockets(uint88(pocketId))), basePocket);
        assertEq(vault.pocketEnabled(uint88(pocketId)), true);
    }

    function test_RevertIf_PocketNotEnabledOnDisable(uint88 pocketId) public {
        vm.assume(pocketId != 1);
        address basePocket = address(new BasePocket(address(vault), address(collateral), address(collateral)));
        vault.addPocket(IPocket(basePocket));
        vm.expectRevert(abi.encodeWithSelector(IVault.PocketNotEnabled.selector, pocketId));
        vault.disablePocket(pocketId);
    }

    // TODO test that deposits to disabled pocket don't work but withdrawals work
    function test_ShouldDisablePocket() public {
        address basePocket = address(new BasePocket(address(vault), address(collateral), address(collateral)));
        vault.addPocket(IPocket(basePocket));
        vm.expectEmit(true, true, false, true);
        emit IVault.PocketDisabled(uint88(1));
        vault.disablePocket(1);
    }
}

contract DepositTest is PocketSetup {
    function test_ShouldDeposit() public {}
}
