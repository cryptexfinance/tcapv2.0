// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "test/util/TestHelpers.sol";

import "../script/deployers/TCAPV2Deployer.s.sol";
import "../script/deployers/VaultDeployer.s.sol";

import {MockFeed} from "./mock/MockFeed.sol";
import {AggregatedChainlinkOracle} from "../src/oracle/AggregatedChainlinkOracle.sol";
import {TCAPTargetOracle} from "../src/oracle/TCAPTargetOracle.sol";
import {MockCollateral} from "./mock/MockCollateral.sol";
import {IPermit2, ISignatureTransfer} from "permit2/src/interfaces/IPermit2.sol";
import {Deploy} from "./util/Deploy.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {BasePocket} from "../src/pockets/BasePocket.sol";
import {Constants, Roles} from "../src/lib/Constants.sol";

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
        vm.warp(block.timestamp + 2 days);
        /// @dev mock collateral has 8 decimals, therefore adjust mint and deposit amounts by 1e10
        collateral = new MockCollateral();
        permit2 = Deploy.permit2();
        deployTCAPV2Transparent(admin, admin);
        tCAPV2.grantRole(Roles.ORACLE_SETTER_ROLE, admin);
        tCAPV2.grantRole(Roles.VAULT_ROLE, admin);
        uint256 collateralPrice = 1000;
        feedTCAP = new MockFeed(collateralPrice * Constants.DIVISOR * 1e8);
        oracleTCAP = new TCAPTargetOracle(tCAPV2, address(feedTCAP));
        tCAPV2.setOracle(address(oracleTCAP));

        feed = new MockFeed(collateralPrice * 1e8);
        oracle = new AggregatedChainlinkOracle(address(feed), address(collateral));

        IVault.LiquidationParams memory liquidationParams = IVault.LiquidationParams({threshold: 1e18, penalty: 0, minHealthFactor: 1, maxHealthFactor: 1e18});

        deployVaultTransparent({
            proxyAdminOwner: admin,
            tCAPV2_: tCAPV2,
            collateral_: collateral,
            permit2_: permit2,
            admin: admin,
            initialFee: 100,
            oracle_: address(oracle),
            feeRecipient_: feeRecipient,
            liquidationParams_: liquidationParams
        });
    }
}

abstract contract Permitted is Initialized {
    function setUp() public virtual override {
        super.setUp();
        tCAPV2.grantRole(Roles.VAULT_ROLE, address(vault));
        vault.grantRole(Roles.POCKET_SETTER_ROLE, admin);
        vault.grantRole(Roles.FEE_SETTER_ROLE, admin);
        vault.grantRole(Roles.ORACLE_SETTER_ROLE, admin);
        vault.grantRole(Roles.LIQUIDATION_SETTER_ROLE, admin);
    }
}

abstract contract PocketSetup is Permitted {
    event Transfer(address indexed from, address indexed to, uint256 value);

    address pocket;
    uint96 pocketId;

    function setUp() public virtual override {
        super.setUp();
        pocket = address(new BasePocket(address(vault), address(collateral), address(collateral)));
        pocketId = vault.addPocket(IPocket(pocket));
    }

    function deposit(address user, uint256 amount) internal returns (uint256) {
        return deposit(user, amount, 1, 1e35 - 1);
    }

    function deposit(address user, uint256 amount, uint256 min, uint256 max) internal returns (uint256) {
        amount = bound(amount, min, max);
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
        IVault.LiquidationParams memory liquidationParams =
            IVault.LiquidationParams({threshold: 1.5e18, penalty: 0.05e18, minHealthFactor: 0.1e18, maxHealthFactor: 0.3e18});
        Vault vault_ = Vault(deployVaultImplementation(tCAPV2, collateral, permit2));
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        vault_.initialize(makeAddr("admin"), 1, makeAddr("oracle"), makeAddr("feeRecipient"), liquidationParams);
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
        vm.expectRevert(abi.encodeWithSelector(AccessControlUnauthorizedAccount.selector, sender, Roles.POCKET_SETTER_ROLE));
        vm.prank(sender);
        vault.addPocket(IPocket(makeAddr("pocket")));
        vm.expectRevert(abi.encodeWithSelector(AccessControlUnauthorizedAccount.selector, sender, Roles.POCKET_SETTER_ROLE));
        vm.prank(sender);
        vault.disablePocket(0);
    }

    function test_RevertIf_InvalidPermission_FeeSetter(address sender) public {
        vm.assume(sender != address(vaultProxyAdmin));
        vm.expectRevert(abi.encodeWithSelector(AccessControlUnauthorizedAccount.selector, sender, Roles.FEE_SETTER_ROLE));
        vm.prank(sender);
        vault.updateInterestRate(0);
        vm.expectRevert(abi.encodeWithSelector(AccessControlUnauthorizedAccount.selector, sender, Roles.FEE_SETTER_ROLE));
        vm.prank(sender);
        vault.updateFeeRecipient(feeRecipient);
    }

    function test_RevertIf_InvalidPermission_OracleSetter(address sender) public {
        vm.assume(sender != address(vaultProxyAdmin));
        vm.expectRevert(abi.encodeWithSelector(AccessControlUnauthorizedAccount.selector, sender, Roles.ORACLE_SETTER_ROLE));
        vm.prank(sender);
        vault.updateOracle(address(0));
    }

    function test_RevertIf_InvalidPermission_LiquidationSetter(address sender) public {
        IVault.LiquidationParams memory liquidationParams =
            IVault.LiquidationParams({threshold: 1.5e18, penalty: 0.05e18, minHealthFactor: 0.1e18, maxHealthFactor: 0.3e18});
        vm.assume(sender != address(vaultProxyAdmin));
        vm.expectRevert(abi.encodeWithSelector(AccessControlUnauthorizedAccount.selector, sender, Roles.LIQUIDATION_SETTER_ROLE));
        vm.prank(sender);
        vault.updateLiquidationParams(liquidationParams);
    }
}

contract ManagementTest is Permitted {
    function test_RevertIf_InterestRateOutOfBounds(uint16 interestRate) public {
        interestRate = uint16(bound(interestRate, Constants.MAX_FEE + 1, type(uint16).max));
        vm.expectRevert(abi.encodeWithSelector(IVault.InvalidValue.selector, IVault.ErrorCode.MAX_FEE));
        vault.updateInterestRate(interestRate);
    }

    function test_ShouldUpdateInterestRate(uint16 interestRate) public {
        interestRate = uint16(bound(interestRate, 1, Constants.MAX_FEE));
        vm.expectEmit(true, true, false, true);
        emit IVault.InterestRateUpdated(interestRate);
        vault.updateInterestRate(interestRate);
        assertEq(vault.interestRate(), interestRate);
    }

    function test_ShouldUpdateFeeRecipient(address feeRecipient_) public {
        vm.assume(feeRecipient_ != address(0));
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

    function test_RevertIf_LiquidationPenaltyExceedsMax(uint64 liquidationPenalty) public {
        liquidationPenalty = uint64(bound(liquidationPenalty, Constants.MAX_LIQUIDATION_PENALTY + 1, type(uint64).max));
        IVault.LiquidationParams memory liquidationParams =
            IVault.LiquidationParams({threshold: 1.5e18, penalty: liquidationPenalty, minHealthFactor: 0.1e18, maxHealthFactor: 0.3e18});
        vm.expectRevert(abi.encodeWithSelector(IVault.InvalidValue.selector, IVault.ErrorCode.MAX_LIQUIDATION_PENALTY));
        vault.updateLiquidationParams(liquidationParams);
    }

    function test_RevertIf_LiquidationThresholdExceedsMax(uint64 liquidationThreshold, uint64 liquidationPenalty) public {
        liquidationPenalty = uint64(bound(liquidationPenalty, 0, Constants.MAX_LIQUIDATION_PENALTY));
        liquidationThreshold = uint64(bound(liquidationThreshold, Constants.MAX_LIQUIDATION_THRESHOLD + liquidationPenalty + 1, type(uint64).max));
        IVault.LiquidationParams memory liquidationParams =
            IVault.LiquidationParams({threshold: liquidationThreshold, penalty: liquidationPenalty, minHealthFactor: 0.1e18, maxHealthFactor: 0.3e18});
        vm.expectRevert(abi.encodeWithSelector(IVault.InvalidValue.selector, IVault.ErrorCode.MAX_LIQUIDATION_THRESHOLD));
        vault.updateLiquidationParams(liquidationParams);
    }

    function test_RevertIf_LiquidationThresholdSubceedsMin(uint64 liquidationThreshold, uint64 liquidationPenalty) public {
        liquidationPenalty = uint64(bound(liquidationPenalty, 0, Constants.MAX_LIQUIDATION_PENALTY));
        liquidationThreshold = uint64(bound(liquidationThreshold, 0, Constants.MIN_LIQUIDATION_THRESHOLD - 1));
        IVault.LiquidationParams memory liquidationParams =
            IVault.LiquidationParams({threshold: liquidationThreshold, penalty: 0.05e18, minHealthFactor: 0.1e18, maxHealthFactor: 0.3e18});
        vm.expectRevert(abi.encodeWithSelector(IVault.InvalidValue.selector, IVault.ErrorCode.MIN_LIQUIDATION_THRESHOLD));
        vault.updateLiquidationParams(liquidationParams);
    }

    function test_RevertIf_PostLiquidationHealthFactorExceedsMax(uint64 maxHealthFactor) public {
        maxHealthFactor = uint64(bound(maxHealthFactor, Constants.MAX_POST_LIQUIDATION_HEALTH_FACTOR + 1, type(uint64).max));
        IVault.LiquidationParams memory liquidationParams =
            IVault.LiquidationParams({threshold: 1.5e18, penalty: 0.05e18, minHealthFactor: 0.1e18, maxHealthFactor: maxHealthFactor});
        vm.expectRevert(abi.encodeWithSelector(IVault.InvalidValue.selector, IVault.ErrorCode.MAX_POST_LIQUIDATION_HEALTH_FACTOR));
        vault.updateLiquidationParams(liquidationParams);
    }

    function test_RevertIf_PostLiquidationHealthFactorSubceedsMin() public {
        IVault.LiquidationParams memory liquidationParams =
            IVault.LiquidationParams({threshold: 1.5e18, penalty: 0.05e18, minHealthFactor: 0, maxHealthFactor: 0.3e18});
        vm.expectRevert(abi.encodeWithSelector(IVault.InvalidValue.selector, IVault.ErrorCode.MIN_POST_LIQUIDATION_HEALTH_FACTOR));
        vault.updateLiquidationParams(liquidationParams);
    }

    function test_RevertIf_PostLiquidationHealthFactorMaxIsLessThanMin(uint64 minHealthFactor, uint64 maxHealthFactor) public {
        minHealthFactor = uint64(bound(minHealthFactor, Constants.MIN_POST_LIQUIDATION_HEALTH_FACTOR + 1, Constants.MAX_POST_LIQUIDATION_HEALTH_FACTOR));
        maxHealthFactor = uint64(bound(maxHealthFactor, Constants.MIN_POST_LIQUIDATION_HEALTH_FACTOR, minHealthFactor - 1));
        IVault.LiquidationParams memory liquidationParams =
            IVault.LiquidationParams({threshold: 1.5e18, penalty: 0.05e18, minHealthFactor: minHealthFactor, maxHealthFactor: maxHealthFactor});
        vm.expectRevert(abi.encodeWithSelector(IVault.InvalidValue.selector, IVault.ErrorCode.INCOMPATIBLE_MAX_POST_LIQUIDATION_HEALTH_FACTOR));
        vault.updateLiquidationParams(liquidationParams);
    }

    function test_ShouldUpdateLiquidationThreshold(IVault.LiquidationParams memory params) public {
        params.penalty = uint64(bound(params.penalty, 0, Constants.MAX_LIQUIDATION_PENALTY));
        params.threshold =
            uint64(bound(params.threshold, Constants.MIN_LIQUIDATION_THRESHOLD + params.penalty + 1, Constants.MAX_LIQUIDATION_THRESHOLD - params.penalty));
        params.minHealthFactor =
            uint64(bound(params.minHealthFactor, Constants.MIN_POST_LIQUIDATION_HEALTH_FACTOR, Constants.MAX_POST_LIQUIDATION_HEALTH_FACTOR - 1));
        params.maxHealthFactor = uint64(bound(params.maxHealthFactor, params.minHealthFactor + 1, Constants.MAX_POST_LIQUIDATION_HEALTH_FACTOR));
        // vm.expectEmit(true, true, false, true);
        // emit IVault.LiquidationParamsUpdated(params);
        vault.updateLiquidationParams(params);
        assertEq(abi.encode(vault.liquidationParams()), abi.encode(params));
    }
}

contract PocketTest is Permitted {
    function test_RevertIf_PocketIsZero() public {
        vm.expectRevert(abi.encodeWithSelector(IVault.InvalidValue.selector, IVault.ErrorCode.ZERO_VALUE));
        vault.addPocket(IPocket(address(0)));
    }

    function test_RevertIf_PocketDoesNotHaveVaultFunction() public {
        vm.expectRevert();
        vault.addPocket(IPocket(makeAddr("pocket")));
    }

    function test_RevertIf_PocketDoesNotPointToVault() public {
        address pocket = address(new BasePocket(makeAddr("vault"), address(collateral), address(collateral)));
        vm.expectRevert(abi.encodeWithSelector(IVault.InvalidValue.selector, IVault.ErrorCode.INVALID_POCKET));
        vault.addPocket(IPocket(pocket));
    }

    function test_RevertIf_PocketDoesNotHaveCorrectUnderlyingToken() public {
        address pocket = address(new BasePocket(address(vault), makeAddr("collateral"), makeAddr("collateral")));
        vm.expectRevert(abi.encodeWithSelector(IVault.InvalidValue.selector, IVault.ErrorCode.INVALID_POCKET_COLLATERAL));
        vault.addPocket(IPocket(pocket));
    }

    function test_ShouldAddPocket() public {
        address basePocket_ = address(new BasePocket(address(vault), address(collateral), address(collateral)));
        uint256 pocketId = 1;
        vm.expectEmit(true, true, false, true);
        emit IVault.PocketAdded(uint96(pocketId), IPocket(basePocket_));
        vault.addPocket(IPocket(basePocket_));
        assertEq(address(vault.pockets(uint96(pocketId))), basePocket_);
        assertEq(vault.pocketEnabled(uint96(pocketId)), true);
    }

    function test_RevertIf_PocketNotEnabledOnDisable(uint96 pocketId) public {
        vm.assume(pocketId != 1);
        address basePocket_ = address(new BasePocket(address(vault), address(collateral), address(collateral)));
        vault.addPocket(IPocket(basePocket_));
        vm.expectRevert(abi.encodeWithSelector(IVault.PocketNotEnabled.selector, pocketId));
        vault.disablePocket(pocketId);
    }

    function test_ShouldDisablePocket() public {
        address basePocket_ = address(new BasePocket(address(vault), address(collateral), address(collateral)));
        vault.addPocket(IPocket(basePocket_));
        vm.expectEmit(true, true, false, true);
        emit IVault.PocketDisabled(uint96(1));
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

    function test_RevertIf_PocketDoesNotExist(uint96 id) public {
        id = uint96(bound(id, 2, type(uint96).max));
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
        amount = bound(amount, 1, 1e35 - 1);
        collateral.mint(user, amount);
        vm.prank(user);
        collateral.approve(address(vault), amount);
        vm.prank(user);
        vm.expectEmit(true, true, false, true);
        emit Transfer(user, address(pocket), amount);
        vm.expectEmit(true, true, false, true);
        emit IVault.Deposited(user, pocketId, amount, amount * Constants.DECIMAL_OFFSET);
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
        amount = bound(amount, 1, 1e35 - 1);
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
        emit IVault.Deposited(user, pocketId, amount, amount * Constants.DECIMAL_OFFSET);
        vault.depositWithPermit(pocketId, amount, permit, signature);
        assertEq(vault.collateralOf(user, pocketId), amount);
    }
}

contract MintTest is PocketSetup {
    function test_ShouldBeAbleToMint(address user, uint256 amount) public {
        vm.assume(user != address(0) && user != address(vaultProxyAdmin));
        uint256 mintAmount = bound(amount, 1, 1e35 - 1);
        deposit(user, bound(amount, mintAmount, 1e35 - 1));
        vm.prank(user);
        vm.expectEmit(true, true, false, true);
        emit IVault.Minted(user, pocketId, mintAmount);
        vault.mint(pocketId, mintAmount);
        assertEq(vault.mintedAmountOf(user, pocketId), mintAmount);
    }

    function test_RevertIf_LoanNotHealthyAfterMint(address user, uint256 amount) public {
        vm.assume(user != address(0) && user != address(vaultProxyAdmin));
        uint256 mintAmount = bound(amount, 1e10 + 1, 1e35 - 1);
        deposit(user, bound(amount, 1, (mintAmount - 1) / 1e10));
        vm.prank(user);
        vm.expectRevert(IVault.LoanNotHealthy.selector);
        vault.mint(pocketId, mintAmount);
    }
}

contract WithdrawalTest is PocketSetup {
    function test_RevertIf_LoanNotHealthyAfterWithdrawal(address user, uint256 amount) public {
        vm.assume(user != address(0) && user != address(vaultProxyAdmin));
        uint256 mintAmount = bound(amount, 1e10, 1e35 - 1);
        uint256 depositAmount = bound(amount, mintAmount, 1e35 - 1) / 1e10 + 1;
        deposit(user, depositAmount);
        vm.prank(user);
        vault.mint(pocketId, mintAmount);
        uint256 burnAmount = bound(amount, depositAmount - mintAmount / 1e10 + 1, depositAmount);
        address recipient = makeAddr("recipient");
        vm.expectRevert(IVault.LoanNotHealthy.selector);
        vm.prank(user);
        vault.withdraw(pocketId, burnAmount, recipient);
    }

    function test_ShouldBeAbleToWithdraw(address user, uint256 amount) public {
        vm.assume(user != address(0) && user != address(vaultProxyAdmin));
        uint256 mintAmount = bound(amount, 1, 1e35 - 3);
        uint256 depositAmount = deposit(user, amount, mintAmount + 1, 1e35 - 1);
        vm.prank(user);
        vault.mint(pocketId, mintAmount);
        uint256 burnAmount = bound(amount, 1, depositAmount - mintAmount);
        address recipient = makeAddr("recipient");
        vm.expectEmit(true, true, false, true);
        emit Transfer(address(pocket), recipient, burnAmount);
        vm.expectEmit(true, true, false, true);
        emit IPocket.Withdrawal(user, recipient, burnAmount, burnAmount, burnAmount * Constants.DECIMAL_OFFSET);
        vm.expectEmit(true, true, false, true);
        emit IVault.Withdrawn(user, pocketId, recipient, burnAmount, burnAmount * Constants.DECIMAL_OFFSET);
        vm.prank(user);
        vault.withdraw(pocketId, burnAmount, recipient);
    }

    function test_ShouldBeAbleToWithdrawWhenPocketIsDisabled(address user, uint256 amount) public {
        vm.assume(user != address(0) && user != address(vaultProxyAdmin));
        uint256 mintAmount = bound(amount, 1, 1e35 - 3);
        uint256 depositAmount = deposit(user, amount, mintAmount + 1, 1e35 - 1);
        vm.prank(user);
        vault.mint(pocketId, mintAmount);
        uint256 burnAmount = bound(amount, 1, depositAmount - mintAmount);
        address recipient = makeAddr("recipient");
        vault.disablePocket(pocketId);
        vm.expectEmit(true, true, false, true);
        emit Transfer(address(pocket), recipient, burnAmount);
        vm.expectEmit(true, true, false, true);
        emit IPocket.Withdrawal(user, recipient, burnAmount, burnAmount, burnAmount * Constants.DECIMAL_OFFSET);
        vm.expectEmit(true, true, false, true);
        emit IVault.Withdrawn(user, pocketId, recipient, burnAmount, burnAmount * Constants.DECIMAL_OFFSET);
        vm.prank(user);
        vault.withdraw(pocketId, burnAmount, recipient);
    }

    function test_ShouldTakeFeeOnWithdrawal(uint32 timestamp) public {
        address user = makeAddr("user");
        uint256 amount = 100 ether;
        deposit(user, amount);
        vm.prank(user);
        vault.mint(pocketId, amount * 1e10 / 10);
        timestamp = uint32(bound(timestamp, block.timestamp + 1, type(uint32).max));
        vm.warp(timestamp);
        uint256 outstandingInterest = vault.outstandingInterestOf(user, pocketId);
        assertGt(outstandingInterest, 0);
        vm.expectEmit(true, true, false, true);
        emit Transfer(address(pocket), feeRecipient, outstandingInterest);
        vm.prank(user);
        vault.withdraw(pocketId, 1, user);
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
        uint256 mintAmount = depositAmount * 1e10;
        vault.mint(pocketId, mintAmount);
        uint256 burnAmount = bound(uint256(keccak256(abi.encode(amount))), 1, mintAmount);
        vm.expectEmit(true, true, false, true);
        emit IVault.Burned(user, pocketId, burnAmount);
        vm.prank(user);
        vault.burn(pocketId, burnAmount);
    }
}

contract LiquidationTest is PocketSetup {
    function test_RevertIf_BurningMoreThanMinted(address user, uint256 amount) public {
        vm.assume(user != address(0) && user != address(vaultProxyAdmin));
        uint256 depositAmount = deposit(user, amount);
        vm.assume(depositAmount > 0);
        uint256 mintAmount = bound(amount, 1, depositAmount);
        vm.prank(user);
        vault.mint(pocketId, mintAmount);
        tCAPV2.mint(address(this), mintAmount);
        vm.expectRevert(abi.encodeWithSelector(IVault.InvalidValue.selector, IVault.ErrorCode.INVALID_BURN_AMOUNT));
        vault.liquidate(user, pocketId, mintAmount + 1);
    }

    function test_RevertIf_LoanHealthyDuringLiquidation(address user, uint256 amount) public {
        vm.assume(user != address(0) && user != address(vaultProxyAdmin));
        uint256 depositAmount = deposit(user, amount, 3, 1e35 - 1);
        vm.prank(user);
        uint256 mintAmount = bound(amount, 1, depositAmount - 1);
        vault.mint(pocketId, mintAmount);
        tCAPV2.mint(address(this), mintAmount);
        vm.expectRevert(IVault.LoanHealthy.selector);
        vault.liquidate(user, pocketId, mintAmount);
    }

    function test_RevertIf_HealthFactorIsBelowMinAfterLiquidation(address user, uint256 amount) public {
        vm.assume(user != address(0) && user != address(vaultProxyAdmin));
        uint256 depositAmount = deposit(user, amount);
        vm.assume(depositAmount > 1e4 && depositAmount < 1e20);
        vm.prank(user);
        uint64 penalty = 0.05e18;
        uint256 mintAmount = depositAmount * 1e10 * 1e18 / (1e18 + penalty * 5);
        vault.mint(pocketId, mintAmount);
        vault.updateLiquidationParams(IVault.LiquidationParams({threshold: 1.5e18, penalty: penalty, minHealthFactor: 0.1e18, maxHealthFactor: 0.3e18}));
        uint256 amountLiquidated = mintAmount * 6 / 10;
        vm.expectRevert(abi.encodeWithSelector(IVault.InvalidValue.selector, IVault.ErrorCode.HEALTH_FACTOR_BELOW_MINIMUM));
        vault.liquidate(user, pocketId, amountLiquidated);
    }

    function test_RevertIf_HealthFactorIsAboveMaxAfterLiquidation(address user, uint256 amount) public {
        vm.assume(user != address(0) && user != address(vaultProxyAdmin));
        uint256 depositAmount = deposit(user, amount);
        vm.assume(depositAmount > 1e4 && depositAmount < 1e20);
        vm.prank(user);
        uint256 mintAmount = depositAmount * 1e10;
        vault.mint(pocketId, mintAmount);
        feedTCAP.setMultiplier(9000);
        vault.updateLiquidationParams(IVault.LiquidationParams({threshold: 1.2e18, penalty: 0, minHealthFactor: 0.1e18, maxHealthFactor: 0.3e18}));
        vm.expectRevert(abi.encodeWithSelector(IVault.InvalidValue.selector, IVault.ErrorCode.HEALTH_FACTOR_ABOVE_MAXIMUM));
        vault.liquidate(user, pocketId, mintAmount * 9 / 10);
    }

    function test_ShouldBeAbleToLiquidate(address user, uint256 amount) public {
        vm.assume(user != address(0) && user != address(vaultProxyAdmin));
        uint256 depositAmount = deposit(user, amount, 1, 1e28);
        vm.prank(user);
        uint256 mintAmount = bound(amount, 1, depositAmount * 1e10);
        vault.mint(pocketId, mintAmount);
        uint256 collateralValue = vault.collateralValueOfUser(user, pocketId);
        uint256 mintValue = vault.mintedValueOf(mintAmount);
        uint256 multiplier = mintValue * 10_000 / (collateralValue);
        vm.assume(multiplier > 1);
        feed.setMultiplier(multiplier - 1);
        tCAPV2.mint(address(this), mintAmount);
        vm.expectEmit(true, true, true, true);
        emit IVault.Liquidated(address(this), user, pocketId, depositAmount, mintAmount);
        vault.liquidate(user, pocketId, mintAmount);
    }
}
