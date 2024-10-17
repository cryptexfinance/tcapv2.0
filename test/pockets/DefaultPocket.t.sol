// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import "test/util/TestHelpers.sol";

import "../../script/deployers/DefaultPocketDeployer.s.sol";
import {IPocket} from "../../src/interface/pockets/IPocket.sol";
import {MockCollateral} from "../mock/MockCollateral.sol";

abstract contract Uninitialized is Test, TestHelpers, DefaultPocketDeployer {
    function setUp() public virtual {
        address vault = makeAddr("vault");
        address tokenUnderlying = makeAddr("tokenUnderlying");
        defaultPocket = DefaultPocket(deployDefaultPocketImplementation(vault, tokenUnderlying));
    }
}

abstract contract Initialized is Uninitialized {
    MockCollateral collateral = new MockCollateral();

    function setUp() public virtual override {
        super.setUp();
        address admin = address(this);
        deployDefaultPocketTransparent(admin, address(this), address(collateral));
    }
}

abstract contract InitialDeposited is Initialized {
    uint256 MAX_AMOUNT = 100 ether;

    function setUp() public virtual override {
        super.setUp();
        uint256 amount = uint256(keccak256("alice")) % MAX_AMOUNT;
        collateral.mint(address(defaultPocket), amount);
        defaultPocket.registerDeposit(makeAddr("alice"), amount);
    }
}

abstract contract Deposited is InitialDeposited {
    function setUp() public virtual override {
        super.setUp();
        uint256 amountBob = uint256(keccak256("bob")) % MAX_AMOUNT;
        uint256 amountCharlie = uint256(keccak256("charlie")) % MAX_AMOUNT;
        uint256 amountDavid = uint256(keccak256("david")) % MAX_AMOUNT;
        collateral.mint(address(defaultPocket), amountBob);
        defaultPocket.registerDeposit(makeAddr("bob"), amountBob);
        collateral.mint(address(defaultPocket), amountCharlie);
        defaultPocket.registerDeposit(makeAddr("charlie"), amountCharlie);
        collateral.mint(address(defaultPocket), amountDavid);
        defaultPocket.registerDeposit(makeAddr("david"), amountDavid);
    }
}

contract UninitializedTest is Uninitialized {
    function test_InitialState() public {
        assertEq(defaultPocket.totalShares(), 0);
        assertEq(address(defaultPocket.VAULT()), makeAddr("vault"));
        assertEq(address(defaultPocket.UNDERLYING_TOKEN()), makeAddr("tokenUnderlying"));
        assertEq(address(defaultPocket.OVERLYING_TOKEN()), makeAddr("tokenUnderlying"));
        assertEq(defaultPocket.version(), "1.0.0");
    }

    function test_RevertsOnInitialization() public {
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        defaultPocket.initialize();
    }
}

contract InitializedTest is Initialized {
    function test_InitialState() public {
        assertEq(defaultPocket.totalShares(), 0);
    }
}

contract PermissionTest is Initialized {
    function test_revertIf_notVault_deposit(address sender) public {
        vm.assume(sender != address(this) && sender != address(defaultPocketProxyAdmin));
        vm.prank(sender);
        vm.expectRevert(IPocket.Unauthorized.selector);
        defaultPocket.registerDeposit(address(1), 1);
    }

    function test_revertIf_notVault_withdraw(address sender) public {
        vm.assume(sender != address(this) && sender != address(defaultPocketProxyAdmin));
        vm.prank(sender);
        vm.expectRevert(IPocket.Unauthorized.selector);
        defaultPocket.withdraw(address(1), 1, address(1));
    }
}

contract InitialDepositTest is Initialized {
    function test_shouldMintInitialShares(uint256 amount) public {
        amount = bound(amount, 1, 1e35 - 1);
        address user = makeAddr("alice");
        collateral.mint(address(defaultPocket), amount);
        vm.expectEmit(true, true, false, true);
        emit IPocket.Deposit(user, amount, amount, amount * Constants.DECIMAL_OFFSET);
        defaultPocket.registerDeposit(user, amount);
        assertEq(defaultPocket.totalShares(), amount * Constants.DECIMAL_OFFSET);
        assertEq(defaultPocket.sharesOf(user), amount * Constants.DECIMAL_OFFSET);
        assertEq(defaultPocket.balanceOf(user), amount);
        assertEq(defaultPocket.totalBalance(), amount);
    }
}

contract SubsequentDepositsTest is InitialDeposited {
    function test_shouldMintSubsequentShares(uint256 amount) public {
        address user = makeAddr("bob");
        amount = bound(amount, 1, 1e35 - 1);
        uint256 totalSharesBefore = defaultPocket.totalShares();
        uint256 totalBalanceBefore = defaultPocket.totalBalance();
        collateral.mint(address(defaultPocket), amount);
        vm.expectEmit(true, true, false, true);
        emit IPocket.Deposit(user, amount, amount, amount * Constants.DECIMAL_OFFSET);
        defaultPocket.registerDeposit(user, amount);
        assertEq(defaultPocket.totalShares(), totalSharesBefore + amount * Constants.DECIMAL_OFFSET);
        assertEq(defaultPocket.sharesOf(user), amount * Constants.DECIMAL_OFFSET);
        assertEq(defaultPocket.balanceOf(user), amount);
        assertEq(defaultPocket.totalBalance(), totalBalanceBefore + amount);
    }
}

contract BalanceFluctuationTest is Deposited {
    function test_shouldAllocateBalancesCorrectlyIfUnderlyingBalanceChanges(int256 balanceChange) public {
        balanceChange = bound(balanceChange, int256(defaultPocket.totalShares()) * -1, int256(type(int128).max)) / int256(Constants.DECIMAL_OFFSET);
        address user = makeAddr("alice");
        uint256 totalBalanceBefore = defaultPocket.totalBalance();
        uint256 totalShares = defaultPocket.totalShares();
        uint256 shares = defaultPocket.sharesOf(user);
        uint256 userBalanceBefore = defaultPocket.balanceOf(user);
        assertEq(shares * totalBalanceBefore / totalShares, userBalanceBefore);
        if (balanceChange < 0) {
            collateral.burn(address(defaultPocket), uint256(balanceChange * -1));
        } else {
            collateral.mint(address(defaultPocket), uint256(balanceChange));
        }
        int256 newBalance = balanceChange * int256(shares) / int256(totalShares) + int256(userBalanceBefore);
        assertApproxEqAbs(uint256(newBalance), defaultPocket.balanceOf(user), 1);
    }
}

contract WithdrawTest is Deposited {
    function test_revertIf_withdrawingMoreSharesThanOwned(uint256 amountUnderlying) public {
        address user = makeAddr("alice");
        amountUnderlying = bound(amountUnderlying, defaultPocket.balanceOf(user) + 1, type(uint256).max / 1e30);
        vm.expectRevert(IPocket.InsufficientFunds.selector);
        defaultPocket.withdraw(user, amountUnderlying, user);
    }

    function test_shouldBurnSharesBase(uint256 amountUnderlying) public {
        address user = makeAddr("alice");
        address recipient = makeAddr("recipient");
        uint256 expectedUnderlying;
        if (amountUnderlying != type(uint256).max) {
            amountUnderlying = bound(amountUnderlying, 0, defaultPocket.balanceOf(user));
            expectedUnderlying = amountUnderlying;
        } else {
            expectedUnderlying = defaultPocket.balanceOf(user);
        }
        uint256 totalSharesBefore = defaultPocket.totalShares();
        uint256 sharesBefore = defaultPocket.sharesOf(user);
        uint256 balanceRecipientBefore = collateral.balanceOf(recipient);
        uint256 balancePocketBefore = collateral.balanceOf(address(defaultPocket));
        uint256 expectedShares = expectedUnderlying * totalSharesBefore / defaultPocket.totalBalance();
        vm.expectEmit(true, true, false, true);
        emit IPocket.Withdrawal(user, recipient, expectedUnderlying, expectedUnderlying, expectedShares);
        defaultPocket.withdraw(user, amountUnderlying, recipient);
        assertEq(defaultPocket.totalShares(), totalSharesBefore - expectedShares);
        assertEq(defaultPocket.sharesOf(user), sharesBefore - expectedShares);
        assertEq(collateral.balanceOf(recipient), balanceRecipientBefore + expectedUnderlying);
        assertEq(collateral.balanceOf(address(defaultPocket)), balancePocketBefore - expectedUnderlying);
    }
}
