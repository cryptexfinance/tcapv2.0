// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import "test/util/TestHelpers.sol";

import "../../script/deployers/BasePocketDeployer.s.sol";
import {MockCollateral} from "../mock/MockCollateral.sol";

abstract contract Uninitialized is Test, TestHelpers, BasePocketDeployer {
    function setUp() public virtual {
        address vault = makeAddr("vault");
        address tokenUnderlying = makeAddr("tokenUnderlying");
        address tokenOverlying = makeAddr("tokenOverlying");
        basePocket = BasePocket(deployBasePocketImplementation(vault, tokenUnderlying, tokenOverlying));
    }
}

abstract contract Initialized is Uninitialized {
    MockCollateral collateral = new MockCollateral();

    function setUp() public virtual override {
        super.setUp();
        address admin = address(this);
        deployBasePocketTransparent(admin, address(this), address(collateral), address(collateral));
    }
}

abstract contract InitialDeposited is Initialized {
    uint256 MAX_AMOUNT = 100 ether;

    function setUp() public virtual override {
        super.setUp();
        uint256 amount = uint256(keccak256("alice")) % MAX_AMOUNT;
        collateral.mint(address(basePocket), amount);
        basePocket.registerDeposit(makeAddr("alice"), amount);
    }
}

abstract contract Deposited is InitialDeposited {
    function setUp() public virtual override {
        super.setUp();
        uint256 amountBob = uint256(keccak256("bob")) % MAX_AMOUNT;
        uint256 amountCharlie = uint256(keccak256("charlie")) % MAX_AMOUNT;
        uint256 amountDavid = uint256(keccak256("david")) % MAX_AMOUNT;
        collateral.mint(address(basePocket), amountBob);
        basePocket.registerDeposit(makeAddr("bob"), amountBob);
        collateral.mint(address(basePocket), amountCharlie);
        basePocket.registerDeposit(makeAddr("charlie"), amountCharlie);
        collateral.mint(address(basePocket), amountDavid);
        basePocket.registerDeposit(makeAddr("david"), amountDavid);
    }
}

contract UninitializedTest is Uninitialized {
    function test_InitialState() public {
        assertEq(basePocket.totalShares(), 0);
        assertEq(address(basePocket.VAULT()), makeAddr("vault"));
        assertEq(address(basePocket.UNDERLYING_TOKEN()), makeAddr("tokenUnderlying"));
        assertEq(address(basePocket.OVERLYING_TOKEN()), makeAddr("tokenOverlying"));
        assertEq(basePocket.version(), "1.0.0");
    }

    function test_RevertsOnInitialization() public {
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        basePocket.initialize();
    }
}

contract InitializedTest is Initialized {
    function test_InitialState() public {
        assertEq(basePocket.totalShares(), 0);
    }
}

contract PermissionTest is Initialized {
    function test_revertIf_notVault_deposit(address sender) public {
        vm.assume(sender != address(this) && sender != address(basePocketProxyAdmin));
        vm.prank(sender);
        vm.expectRevert(IPocket.Unauthorized.selector);
        basePocket.registerDeposit(address(1), 1);
    }

    function test_revertIf_notVault_withdraw(address sender) public {
        vm.assume(sender != address(this) && sender != address(basePocketProxyAdmin));
        vm.prank(sender);
        vm.expectRevert(IPocket.Unauthorized.selector);
        basePocket.withdraw(address(1), 1, address(1));
    }
}

contract InitialDepositTest is Initialized {
    function test_shouldMintInitialShares(uint256 amount) public {
        amount = bound(amount, 1, 1e35 - 1);
        address user = makeAddr("alice");
        collateral.mint(address(basePocket), amount);
        vm.expectEmit(true, true, false, true);
        emit IPocket.Deposit(user, amount, amount, amount * Constants.DECIMAL_OFFSET);
        basePocket.registerDeposit(user, amount);
        assertEq(basePocket.totalShares(), amount * Constants.DECIMAL_OFFSET);
        assertEq(basePocket.sharesOf(user), amount * Constants.DECIMAL_OFFSET);
        assertEq(basePocket.balanceOf(user), amount);
        assertEq(basePocket.totalBalance(), amount);
    }
}

contract SubsequentDepositsTest is InitialDeposited {
    function test_shouldMintSubsequentShares(uint256 amount) public {
        address user = makeAddr("bob");
        amount = bound(amount, 1, 1e35 - 1);
        uint256 totalSharesBefore = basePocket.totalShares();
        uint256 totalBalanceBefore = basePocket.totalBalance();
        collateral.mint(address(basePocket), amount);
        vm.expectEmit(true, true, false, true);
        emit IPocket.Deposit(user, amount, amount, amount * Constants.DECIMAL_OFFSET);
        basePocket.registerDeposit(user, amount);
        assertEq(basePocket.totalShares(), totalSharesBefore + amount * Constants.DECIMAL_OFFSET);
        assertEq(basePocket.sharesOf(user), amount * Constants.DECIMAL_OFFSET);
        assertEq(basePocket.balanceOf(user), amount);
        assertEq(basePocket.totalBalance(), totalBalanceBefore + amount);
    }
}

contract BalanceFluctuationTest is Deposited {
    function test_shouldAllocateBalancesCorrectlyIfUnderlyingBalanceChanges(int256 balanceChange) public {
        balanceChange = bound(balanceChange, int256(basePocket.totalShares()) * -1, int256(type(int128).max)) / int256(Constants.DECIMAL_OFFSET);
        address user = makeAddr("alice");
        uint256 totalBalanceBefore = basePocket.totalBalance();
        uint256 totalShares = basePocket.totalShares();
        uint256 shares = basePocket.sharesOf(user);
        uint256 userBalanceBefore = basePocket.balanceOf(user);
        assertEq(shares * totalBalanceBefore / totalShares, userBalanceBefore);
        if (balanceChange < 0) {
            collateral.burn(address(basePocket), uint256(balanceChange * -1));
        } else {
            collateral.mint(address(basePocket), uint256(balanceChange));
        }
        int256 newBalance = balanceChange * int256(shares) / int256(totalShares) + int256(userBalanceBefore);
        assertApproxEqAbs(uint256(newBalance), basePocket.balanceOf(user), 1);
    }
}

contract WithdrawTest is Deposited {
    function test_revertIf_withdrawingMoreSharesThanOwned(uint256 amountUnderlying) public {
        address user = makeAddr("alice");
        amountUnderlying = bound(amountUnderlying, basePocket.balanceOf(user) + 1, type(uint256).max / 1e30);
        vm.expectRevert(IPocket.InsufficientFunds.selector);
        basePocket.withdraw(user, amountUnderlying, user);
    }

    function test_shouldBurnSharesBase(uint256 amountUnderlying) public {
        address user = makeAddr("alice");
        address recipient = makeAddr("recipient");
        uint256 expectedUnderlying;
        if (amountUnderlying != type(uint256).max) {
            amountUnderlying = bound(amountUnderlying, 0, basePocket.balanceOf(user));
            expectedUnderlying = amountUnderlying;
        } else {
            expectedUnderlying = basePocket.balanceOf(user);
        }
        uint256 totalSharesBefore = basePocket.totalShares();
        uint256 sharesBefore = basePocket.sharesOf(user);
        uint256 balanceRecipientBefore = collateral.balanceOf(recipient);
        uint256 balancePocketBefore = collateral.balanceOf(address(basePocket));
        uint256 expectedShares = expectedUnderlying * totalSharesBefore / basePocket.totalBalance();
        vm.expectEmit(true, true, false, true);
        emit IPocket.Withdrawal(user, recipient, expectedUnderlying, expectedUnderlying, expectedShares);
        basePocket.withdraw(user, amountUnderlying, recipient);
        assertEq(basePocket.totalShares(), totalSharesBefore - expectedShares);
        assertEq(basePocket.sharesOf(user), sharesBefore - expectedShares);
        assertEq(collateral.balanceOf(recipient), balanceRecipientBefore + expectedUnderlying);
        assertEq(collateral.balanceOf(address(basePocket)), balancePocketBefore - expectedUnderlying);
    }
}
