// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import "test/util/TestHelpers.sol";

import "script/deployers/AAVEv3PocketDeployer.s.sol";
import {MockCollateral} from "../mock/MockCollateral.sol";
import {IWETH9, IERC20} from "../interface/IWETH9.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract Uninitialized is Test, TestHelpers, AAVEv3PocketDeployer {
    address POOL_MAINNET = 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2;
    IWETH9 underlyingToken = IWETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IERC20 overlyingAToken = IERC20(0x4d5F47FA6A74757f35C14fD3a6Ef8E3C9BC514E8);
    bool forked = false;

    function setUp() public virtual {
        try vm.envString("INFURA_KEY") returns (string memory infuraKey) {
            string memory rpcUrl = string.concat("https://mainnet.infura.io/v3/", infuraKey);
            vm.createSelectFork(rpcUrl);
            forked = true;
        } catch {}

        address vault = makeAddr("vault");
        aAVEv3Pocket = AAVEv3Pocket(deployAAVEv3PocketImplementation(vault, address(underlyingToken), address(overlyingAToken), POOL_MAINNET));
    }

    modifier onlyForked() {
        if (forked) {
            _;
        }
    }
}

abstract contract Initialized is Uninitialized {
    function setUp() public virtual override {
        super.setUp();
        address admin = address(this);
        deployAAVEv3PocketTransparent(admin, address(this), address(underlyingToken), address(overlyingAToken), POOL_MAINNET);
    }
}

abstract contract Deposited is Initialized {
    uint256 MAX_AMOUNT = 100 ether;

    function setUp() public virtual override onlyForked {
        super.setUp();
        uint256 amount = uint256(keccak256("alice")) % MAX_AMOUNT;
        vm.deal(address(this), amount);
        underlyingToken.deposit{value: amount}();
        underlyingToken.transfer(address(aAVEv3Pocket), amount);
        aAVEv3Pocket.registerDeposit(makeAddr("alice"), amount);
    }
}

contract UninitializedTest is Uninitialized {
    function test_InitialState() public {
        assertEq(aAVEv3Pocket.totalShares(), 0);
        assertEq(address(aAVEv3Pocket.VAULT()), makeAddr("vault"));
        assertEq(address(aAVEv3Pocket.UNDERLYING_TOKEN()), address(underlyingToken));
        assertEq(address(aAVEv3Pocket.OVERLYING_TOKEN()), address(overlyingAToken));
        assertEq(address(aAVEv3Pocket.POOL()), POOL_MAINNET);
    }

    function test_RevertsOnInitialization() public {
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        aAVEv3Pocket.initialize();
    }
}

contract InitializedTest is Initialized {
    function test_InitialState() public onlyForked {
        assertEq(aAVEv3Pocket.totalShares(), 0);
        assertEq(underlyingToken.balanceOf(address(aAVEv3Pocket)), 0);
        assertEq(overlyingAToken.balanceOf(address(aAVEv3Pocket)), 0);
    }
}

contract DepositTest is Initialized {
    function test_shouldMintInitialShares(uint256 amount) public onlyForked {
        amount = bound(amount, 1, 1000 ether);
        address user = makeAddr("alice");
        vm.deal(address(this), amount);
        underlyingToken.deposit{value: amount}();
        underlyingToken.transfer(address(aAVEv3Pocket), amount);
        vm.expectEmit(true, true, false, true);
        emit IPocket.Deposit(user, amount, amount, amount);
        aAVEv3Pocket.registerDeposit(user, amount);
        assertEq(aAVEv3Pocket.totalShares(), amount);
        assertEq(aAVEv3Pocket.sharesOf(user), amount);
        assertApproxEqAbs(aAVEv3Pocket.balanceOf(user), amount, 1);
        assertApproxEqAbs(aAVEv3Pocket.totalBalance(), amount, 1);
    }
}

contract WithdrawTest is Deposited {
    function test_revertIf_withdrawingMoreSharesThanOwned(uint256 shares) public onlyForked {
        address user = makeAddr("alice");
        shares = bound(shares, aAVEv3Pocket.sharesOf(user) + 1, type(uint256).max);
        vm.expectRevert(IPocket.InsufficientFunds.selector);
        aAVEv3Pocket.withdraw(user, shares, user);
    }

    function test_shouldBurnShares(uint256 shares) public onlyForked {
        address user = makeAddr("alice");
        address recipient = makeAddr("recipient");
        shares = bound(shares, 0, aAVEv3Pocket.sharesOf(user));
        uint256 totalSharesBefore = aAVEv3Pocket.totalShares();
        uint256 sharesBefore = aAVEv3Pocket.sharesOf(user);
        uint256 balanceRecipientBefore = underlyingToken.balanceOf(recipient);
        uint256 balancePocketBefore = overlyingAToken.balanceOf(address(aAVEv3Pocket));
        vm.expectEmit(true, true, false, true);
        emit IPocket.Withdraw(user, recipient, shares, shares, shares);
        aAVEv3Pocket.withdraw(user, shares, recipient);
        assertEq(aAVEv3Pocket.totalShares(), totalSharesBefore - shares, "1");
        assertEq(aAVEv3Pocket.sharesOf(user), sharesBefore - shares, "2");
        assertEq(underlyingToken.balanceOf(recipient), balanceRecipientBefore + shares, "3");
        assertApproxEqAbs(overlyingAToken.balanceOf(address(aAVEv3Pocket)), balancePocketBefore - shares, 1);
    }
}
