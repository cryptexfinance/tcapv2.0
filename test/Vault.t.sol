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
import {IPermit2, ISignatureTransfer} from "permit2/src/interfaces/IPermit2.sol";
import {Deploy} from "./util/Deploy.sol";
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
        uint256 collateralPrice = 1000;
        feedTCAP = new MockFeed(collateralPrice * tCAPV2.DIVISOR() * 1e8);
        oracleTCAP = new TCAPTargetOracle(tCAPV2, address(feedTCAP));
        tCAPV2.setOracle(address(oracleTCAP));

        feed = new MockFeed(collateralPrice * 1e8);
        oracle = new AggregatedChainlinkOracle(address(feed), address(collateral));

        deployVaultTransparent({
            proxyAdminOwner: admin,
            tCAPV2_: tCAPV2,
            collateral_: collateral,
            permit2_: permit2,
            admin: admin,
            initialFee: 100,
            oracle_: address(oracle),
            feeRecipient_: feeRecipient,
            liquidationThreshold_: 1 ether
        });
    }
}

abstract contract Permitted is Initialized {
    function setUp() public virtual override {
        super.setUp();
        tCAPV2.grantRole(tCAPV2.VAULT_ROLE(), address(vault));
        vault.grantRole(vault.POCKET_SETTER_ROLE(), admin);
        vault.grantRole(vault.FEE_SETTER_ROLE(), admin);
        vault.grantRole(vault.ORACLE_SETTER_ROLE(), admin);
        vault.grantRole(vault.LIQUIDATION_SETTER_ROLE(), admin);
    }
}

abstract contract PocketSetup is Permitted {
    event Transfer(address indexed from, address indexed to, uint256 value);

    address pocket;
    uint88 pocketId;

    function setUp() public virtual override {
        super.setUp();
        pocket = address(new BasePocket(address(vault), address(collateral), address(collateral)));
        pocketId = vault.addPocket(IPocket(pocket));
    }

    function deposit(address user, uint256 amount) internal returns (uint256) {
        if (amount > 1e38 - 1) amount = 1e38 - 1;
        collateral.mint(user, amount);
        vm.prank(user);
        collateral.approve(address(vault), amount);
        vm.prank(user);
        vault.deposit(pocketId, amount);
        return amount;
    }

    function getPermitTransferSignature(ISignatureTransfer.PermitTransferFrom memory permit, uint256 privateKey) internal view returns (bytes memory sig) {
        bytes32 domainSeparator = keccak256(
            abi.encode(keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)"), keccak256("Permit2"), block.chainid, address(permit2))
        );
        bytes32 tokenPermissions = keccak256(abi.encode(keccak256("TokenPermissions(address token,uint256 amount)"), permit.permitted));
        bytes32 msgHash = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                keccak256(
                    abi.encode(
                        keccak256(
                            "PermitTransferFrom(TokenPermissions permitted,address spender,uint256 nonce,uint256 deadline)TokenPermissions(address token,uint256 amount)"
                        ),
                        tokenPermissions,
                        address(vault),
                        permit.nonce,
                        permit.deadline
                    )
                )
            )
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, msgHash);
        return bytes.concat(r, s, bytes1(v));
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
    function test_RevertIf_PocketIdIsZero() public {
        vm.expectRevert(abi.encodeWithSelector(IVault.PocketNotEnabled.selector, 0));
        vault.deposit(0, 1);
        vm.expectRevert(abi.encodeWithSelector(IVault.PocketNotEnabled.selector, 0));
        ISignatureTransfer.PermitTransferFrom memory permit = ISignatureTransfer.PermitTransferFrom({
            permitted: ISignatureTransfer.TokenPermissions({token: address(collateral), amount: 1}),
            nonce: 1,
            deadline: block.timestamp
        });
        vault.depositWithPermit(0, 1, permit, "");
    }

    function test_RevertIf_PocketDoesNotExist(uint88 id) public {
        id = uint88(bound(id, 2, type(uint88).max));
        vm.expectRevert(abi.encodeWithSelector(IVault.PocketNotEnabled.selector, id));
        vault.deposit(id, 1);
        vm.expectRevert(abi.encodeWithSelector(IVault.PocketNotEnabled.selector, id));
        ISignatureTransfer.PermitTransferFrom memory permit = ISignatureTransfer.PermitTransferFrom({
            permitted: ISignatureTransfer.TokenPermissions({token: address(collateral), amount: 1}),
            nonce: 1,
            deadline: block.timestamp
        });
        vault.depositWithPermit(id, 1, permit, "");
    }

    function test_RevertIf_PocketIsDisabled() public {
        vault.disablePocket(pocketId);
        vm.expectRevert(abi.encodeWithSelector(IVault.PocketNotEnabled.selector, pocketId));
        vault.deposit(pocketId, 1);
        vm.expectRevert(abi.encodeWithSelector(IVault.PocketNotEnabled.selector, pocketId));
        ISignatureTransfer.PermitTransferFrom memory permit = ISignatureTransfer.PermitTransferFrom({
            permitted: ISignatureTransfer.TokenPermissions({token: address(collateral), amount: 1}),
            nonce: 1,
            deadline: block.timestamp
        });
        vault.depositWithPermit(pocketId, 1, permit, "");
    }

    function test_ShouldBeAbleToDeposit(address user, uint256 amount) public {
        vm.assume(user != address(0) && user != address(vaultProxyAdmin));
        amount = bound(amount, 0, 1e38 - 1);
        collateral.mint(user, amount);
        vm.prank(user);
        collateral.approve(address(vault), amount);
        vm.prank(user);
        vm.expectEmit(true, true, false, true);
        emit Transfer(user, address(pocket), amount);
        vm.expectEmit(true, true, false, true);
        emit IVault.Deposited(user, pocketId, amount, amount);
        vault.deposit(pocketId, amount);
        assertEq(vault.collateralOf(user, pocketId), amount);
    }

    function test_RevertIf_PermitIsNotForCollateral(address token) public {
        vm.assume(token != address(collateral));
        ISignatureTransfer.PermitTransferFrom memory permit = ISignatureTransfer.PermitTransferFrom({
            permitted: ISignatureTransfer.TokenPermissions({token: token, amount: 1}),
            nonce: 1,
            deadline: block.timestamp
        });
        vm.expectRevert(IVault.InvalidToken.selector);
        vault.depositWithPermit(pocketId, 1, permit, "");
    }

    function test_ShouldBeAbleToPermitDeposit(uint256 amount) public {
        amount = bound(amount, 0, 1e38 - 1);
        (address user, uint256 privateKey) = makeAddrAndKey("user");
        vm.assume(user != address(0) && user != address(vaultProxyAdmin));
        collateral.mint(user, amount);
        vm.prank(user);
        collateral.approve(address(permit2), type(uint256).max);
        ISignatureTransfer.PermitTransferFrom memory permit = ISignatureTransfer.PermitTransferFrom({
            permitted: ISignatureTransfer.TokenPermissions({token: address(collateral), amount: type(uint256).max}),
            nonce: 1,
            deadline: block.timestamp
        });
        bytes memory signature = getPermitTransferSignature(permit, privateKey);
        vm.prank(user);
        vm.expectEmit(true, true, false, true);
        emit Transfer(user, address(pocket), amount);
        vm.expectEmit(true, true, false, true);
        emit IVault.Deposited(user, pocketId, amount, amount);
        vault.depositWithPermit(pocketId, amount, permit, signature);
        assertEq(vault.collateralOf(user, pocketId), amount);
    }
}

contract MintTest is PocketSetup {
    function test_ShouldBeAbleToMint(address user, uint256 amount) public {
        vm.assume(user != address(0) && user != address(vaultProxyAdmin));
        uint256 mintAmount = bound(amount, 1, 1e38 - 1);
        deposit(user, bound(amount, mintAmount, 1e38 - 1));
        vm.prank(user);
        vm.expectEmit(true, true, false, true);
        emit IVault.Minted(user, pocketId, mintAmount);
        vault.mint(pocketId, mintAmount);
        assertEq(vault.mintedAmountOf(user, pocketId), mintAmount);
    }

    function test_RevertIf_LoanNotHealthyAfterMint(address user, uint256 amount) public {
        vm.assume(user != address(0) && user != address(vaultProxyAdmin));
        uint256 mintAmount = bound(amount, 1, 1e38 - 1);
        deposit(user, bound(amount, 0, mintAmount - 1));
        vm.prank(user);
        vm.expectRevert(IVault.LoanNotHealthy.selector);
        vault.mint(pocketId, mintAmount);
    }
}

contract WithdrawalTest is PocketSetup {
    function test_RevertIf_LoanNotHealthyAfterWithdrawal(address user, uint256 amount) public {
        vm.assume(user != address(0) && user != address(vaultProxyAdmin));
        uint256 mintAmount = bound(amount, 1, 1e38 - 1);
        uint256 depositAmount = bound(amount, mintAmount, 1e38 - 1);
        deposit(user, depositAmount);
        vm.prank(user);
        vault.mint(pocketId, mintAmount);
        uint256 burnAmount = bound(amount, depositAmount - mintAmount + 1, depositAmount);
        address recipient = makeAddr("recipient");
        vm.expectRevert(IVault.LoanNotHealthy.selector);
        vm.prank(user);
        vault.withdraw(pocketId, burnAmount, recipient);
    }

    function test_ShouldBeAbleToWithdraw(address user, uint256 amount) public {
        vm.assume(user != address(0) && user != address(vaultProxyAdmin));
        uint256 mintAmount = bound(amount, 1, 1e38 - 1);
        uint256 depositAmount = bound(amount, mintAmount, 1e38 - 1);
        deposit(user, depositAmount);
        vm.prank(user);
        vault.mint(pocketId, mintAmount);
        uint256 burnAmount = bound(amount, 0, depositAmount - mintAmount);
        address recipient = makeAddr("recipient");
        vm.expectEmit(true, true, false, true);
        emit Transfer(address(pocket), recipient, burnAmount);
        vm.expectEmit(true, true, false, true);
        emit IPocket.Withdrawal(user, recipient, burnAmount, burnAmount, burnAmount);
        vm.expectEmit(true, true, false, true);
        emit IVault.Withdrawn(user, pocketId, recipient, burnAmount, burnAmount);
        vm.prank(user);
        vault.withdraw(pocketId, burnAmount, recipient);
    }

    function test_ShouldBeAbleToWithdrawWhenPocketIsDisabled(address user, uint256 amount) public {
        vm.assume(user != address(0) && user != address(vaultProxyAdmin));
        uint256 mintAmount = bound(amount, 1, 1e38 - 1);
        uint256 depositAmount = bound(amount, mintAmount, 1e38 - 1);
        deposit(user, depositAmount);
        vm.prank(user);
        vault.mint(pocketId, mintAmount);
        uint256 burnAmount = bound(amount, 0, depositAmount - mintAmount);
        address recipient = makeAddr("recipient");
        vault.disablePocket(pocketId);
        vm.expectEmit(true, true, false, true);
        emit Transfer(address(pocket), recipient, burnAmount);
        vm.expectEmit(true, true, false, true);
        emit IPocket.Withdrawal(user, recipient, burnAmount, burnAmount, burnAmount);
        vm.expectEmit(true, true, false, true);
        emit IVault.Withdrawn(user, pocketId, recipient, burnAmount, burnAmount);
        vm.prank(user);
        vault.withdraw(pocketId, burnAmount, recipient);
    }

    function test_ShouldTakeFeeOnWithdrawal(uint32 timestamp) public {
        address user = makeAddr("user");
        uint256 amount = 100 ether;
        deposit(user, amount);
        vm.prank(user);
        vault.mint(pocketId, amount / 10);
        timestamp = uint32(bound(timestamp, block.timestamp + 1, type(uint32).max));
        vm.warp(timestamp);
        uint256 outstandingInterest = vault.outstandingInterestOf(user, pocketId);
        assert(outstandingInterest > 0);
        vm.expectEmit(true, true, false, true);
        emit Transfer(address(pocket), feeRecipient, outstandingInterest);
        vm.prank(user);
        vault.withdraw(pocketId, 0, user);
    }
}

contract BurnTest is PocketSetup {
    function test_RevertIf_BurningMoreThanMinted(address user, uint256 amount) public {
        vm.assume(user != address(0) && user != address(vaultProxyAdmin));
        uint256 depositAmount = deposit(user, amount);
        vm.prank(user);
        vault.mint(pocketId, depositAmount);
        uint256 burnAmount = bound(uint256(keccak256(abi.encode(amount))), depositAmount + 1, type(uint256).max);
        vm.expectRevert(IVault.InsufficientMintedAmount.selector);
        vm.prank(user);
        vault.burn(pocketId, burnAmount);
    }

    function test_ShouldBeAbleToBurn(address user, uint256 amount) public {
        vm.assume(user != address(0) && user != address(vaultProxyAdmin));
        uint256 depositAmount = deposit(user, amount);
        vm.prank(user);
        vault.mint(pocketId, depositAmount);
        uint256 burnAmount = bound(uint256(keccak256(abi.encode(amount))), 0, depositAmount);
        vm.expectEmit(true, true, false, true);
        emit IVault.Burned(user, pocketId, burnAmount);
        vm.prank(user);
        vault.burn(pocketId, burnAmount);
    }
}

contract LiquidationTest is PocketSetup {
    function test_RevertIf_LoanHealthyDuringLiquidation(address user, uint256 amount) public {
        vm.assume(user != address(0) && user != address(vaultProxyAdmin));
        uint256 depositAmount = deposit(user, amount);
        vm.prank(user);
        uint256 mintAmount = bound(amount, 0, depositAmount == 0 ? 0 : depositAmount - 1);
        vault.mint(pocketId, mintAmount);
        tCAPV2.mint(address(this), mintAmount);
        vm.expectRevert(IVault.LoanHealthy.selector);
        vault.liquidate(user, pocketId);
    }

    function test_ShouldBeAbleToLiquidate(address user, uint256 amount) public {
        vm.assume(user != address(0) && user != address(vaultProxyAdmin));
        uint256 depositAmount = deposit(user, amount);
        vm.assume(depositAmount > 0);
        vm.prank(user);
        uint256 mintAmount = bound(amount, 1, depositAmount);
        vault.mint(pocketId, mintAmount);
        uint256 collateralValue = vault.collateralValueOfUser(user, pocketId);
        uint256 mintValue = vault.mintedValueOf(mintAmount);
        uint256 multiplier = mintValue * 10_000 / (collateralValue) - 1;
        feed.setMultiplier(multiplier);
        tCAPV2.mint(address(this), mintAmount);
        vm.expectEmit(true, true, true, true);
        emit IVault.Liquidated(address(this), user, pocketId, depositAmount, mintAmount);
        vault.liquidate(user, pocketId);
    }
}
