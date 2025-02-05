// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import "test/util/TestHelpers.sol";

import "../../script/deployers/AaveV3PocketDeployer.s.sol";
import {MockCollateral} from "../mock/MockCollateral.sol";
import {IWETH9, IERC20} from "../interface/IWETH9.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IPocket} from "../../src/interface/pockets/IPocket.sol";
import {Constants} from "../../src/lib/Constants.sol";
import {IPool} from "@aave/interfaces/IPool.sol";

abstract contract Uninitialized is Test, TestHelpers, AaveV3PocketDeployer {
    address POOL_MAINNET = 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2;
    IWETH9 underlyingToken = IWETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IERC20 overlyingAToken = IERC20(0x4d5F47FA6A74757f35C14fD3a6Ef8E3C9BC514E8);
    bool forked;

    function setUp() public virtual {
        forked = false;
        try vm.envString("INFURA_KEY") returns (string memory infuraKey) {
            string memory rpcUrl = string.concat("https://mainnet.infura.io/v3/", infuraKey);
            vm.createSelectFork(rpcUrl);
            forked = true;
            console2.log("Forked Ethereum mainnet");
            address vault = makeAddr("vault");
            aaveV3Pocket = AaveV3Pocket(deployAaveV3PocketImplementation(vault, address(underlyingToken), POOL_MAINNET));
        } catch {
            console2.log("Skipping forked tests, no infura key found. Add key to .env to run forked tests.");
        }
    }

    modifier onlyForked() {
        if (forked) {
            console2.log("running forked test");
            _;
            return;
        }
        console2.log("skipping forked test");
    }
}

abstract contract Initialized is Uninitialized {
    function setUp() public virtual override {
        super.setUp();
        if (forked) {
            address admin = address(this);
            deployAaveV3PocketTransparent(admin, address(this), address(underlyingToken), POOL_MAINNET);
        }
    }

    function deposit(uint256 amount) internal {
        vm.deal(address(this), amount);
        underlyingToken.deposit{value: amount}();
        underlyingToken.transfer(address(aaveV3Pocket), amount);
    }
}

abstract contract Deposited is Initialized {
    uint256 MAX_AMOUNT = 100 ether;

    function setUp() public virtual override {
        super.setUp();
        if (forked) {
            uint256 amount = uint256(keccak256("alice")) % MAX_AMOUNT;
            vm.deal(address(this), amount);
            underlyingToken.deposit{value: amount}();
            underlyingToken.transfer(address(aaveV3Pocket), amount);
            aaveV3Pocket.registerDeposit(makeAddr("alice"), amount);
        }
    }
}

contract UninitializedTest is Uninitialized {
    function test_InitialState() public onlyForked {
        assertEq(aaveV3Pocket.totalShares(), 0);
        assertEq(address(aaveV3Pocket.VAULT()), makeAddr("vault"));
        assertEq(address(aaveV3Pocket.UNDERLYING_TOKEN()), address(underlyingToken));
        assertEq(address(aaveV3Pocket.OVERLYING_TOKEN()), address(overlyingAToken));
        assertEq(address(aaveV3Pocket.POOL()), POOL_MAINNET);
        assertEq(aaveV3Pocket.version(), "1.0.0");
    }

    function test_RevertsOnInitialization() public onlyForked {
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        aaveV3Pocket.initialize();
    }
}

contract InitializedTest is Initialized {
    function test_InitialState() public onlyForked {
        assertEq(aaveV3Pocket.totalShares(), 0);
        assertEq(underlyingToken.balanceOf(address(aaveV3Pocket)), 0);
        assertEq(overlyingAToken.balanceOf(address(aaveV3Pocket)), 0);
    }
}

contract DepositTest is Initialized {
    function test_ShouldMitigateInflationAttack(uint256 donationAmount, uint256 victimAmount) public onlyForked {
        uint256 dust = 1;
        // maximum victim amount is 0.1 ether, if it is higher, the donation will trigger a supply cap error on aave
        victimAmount = bound(victimAmount, 1, 0.1 ether);
        // inflation attack donation amount is less than victim amount * 1e6. Subtract 1 additional wei due to aave rounding errors
        uint256 donation = bound(donationAmount, victimAmount, victimAmount * 1e6 - 1 - 1);
        assertEq(underlyingToken.balanceOf(address(aaveV3Pocket)), 0);
        address attacker = makeAddr("attacker");

        // transfer dust
        deposit(dust);
        aaveV3Pocket.registerDeposit(attacker, dust);

        // donate overlying
        vm.deal(address(this), donation);
        underlyingToken.deposit{value: donation}();
        underlyingToken.approve(POOL_MAINNET, donation);
        IPool(POOL_MAINNET).supply(address(underlyingToken), donation, address(aaveV3Pocket), 0);
        assertApproxEqAbs(overlyingAToken.balanceOf(address(aaveV3Pocket)), donation + dust, 1);

        address victim = makeAddr("victim");
        deposit(victimAmount);
        aaveV3Pocket.registerDeposit(victim, victimAmount);
        // ensure shares were minted to the victim
        assertGt(aaveV3Pocket.sharesOf(victim), 0);
        // ensure the victim's balance is equal to the amount deposited +- 1 wei due to rounding errors on aave
        assertApproxEqAbs(aaveV3Pocket.balanceOf(victim), victimAmount, 1);
    }

    function test_shouldMintInitialShares(uint256 amount) public onlyForked {
        amount = bound(amount, 1, 1000 ether);
        address user = makeAddr("alice");
        vm.deal(address(this), amount);
        underlyingToken.deposit{value: amount}();
        underlyingToken.transfer(address(aaveV3Pocket), amount);
        vm.expectEmit(true, true, false, true);
        emit IPocket.Deposit(user, amount, amount, amount * Constants.DECIMAL_OFFSET);
        aaveV3Pocket.registerDeposit(user, amount);
        assertEq(aaveV3Pocket.totalShares(), amount * Constants.DECIMAL_OFFSET);
        assertEq(aaveV3Pocket.sharesOf(user), amount * Constants.DECIMAL_OFFSET);
        assertApproxEqAbs(aaveV3Pocket.balanceOf(user), amount, 1);
        assertApproxEqAbs(aaveV3Pocket.totalBalance(), amount, 1);
    }
}

contract WithdrawTest is Deposited {
    function test_revertIf_withdrawingMoreSharesThanOwned(uint256 shares) public onlyForked {
        address user = makeAddr("alice");
        shares = bound(shares, aaveV3Pocket.sharesOf(user) + 1, type(uint128).max - 1);
        vm.expectRevert(IPocket.InsufficientFunds.selector);
        aaveV3Pocket.withdraw(user, shares, user);
    }

    function test_shouldBurnSharesAave(uint256 amount) public onlyForked {
        address user = makeAddr("alice");
        address recipient = makeAddr("recipient");
        amount = bound(amount, 0, aaveV3Pocket.balanceOf(user));
        uint256 totalSharesBefore = aaveV3Pocket.totalShares();
        uint256 shares = amount * Constants.DECIMAL_OFFSET;
        uint256 sharesBefore = aaveV3Pocket.sharesOf(user);
        uint256 balanceRecipientBefore = underlyingToken.balanceOf(recipient);
        uint256 balancePocketBefore = overlyingAToken.balanceOf(address(aaveV3Pocket));
        vm.expectEmit(true, true, false, true);
        emit IPocket.Withdrawal(user, recipient, amount, amount, shares);
        aaveV3Pocket.withdraw(user, amount, recipient);
        assertEq(aaveV3Pocket.totalShares(), totalSharesBefore - shares);
        assertEq(aaveV3Pocket.sharesOf(user), sharesBefore - shares);
        assertEq(underlyingToken.balanceOf(recipient), balanceRecipientBefore + amount);
        assertApproxEqAbs(overlyingAToken.balanceOf(address(aaveV3Pocket)), balancePocketBefore - amount, 1);
    }
}
