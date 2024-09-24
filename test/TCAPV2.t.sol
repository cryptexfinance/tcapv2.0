// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import "test/util/TestHelpers.sol";

import "../script/deployers/TCAPV2Deployer.s.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {MockFeed} from "./mock/MockFeed.sol";
import {MockCollateral} from "./mock/MockCollateral.sol";
import {TCAPTargetOracle} from "../src/oracle/TCAPTargetOracle.sol";
import {AggregatedChainlinkOracle} from "../src/oracle/AggregatedChainlinkOracle.sol";
import {TCAPDeployer} from "script/DeployTCAP.s.sol";
import {AggregatorV3Interface} from "@chainlink/interfaces/feeds/AggregatorV3Interface.sol";
import {Constants, Roles} from "../src/lib/Constants.sol";

abstract contract Uninitialized is Test, TestHelpers, TCAPV2Deployer {
    function setUp() public virtual {
        tCAPV2 = TCAPV2(deployTCAPV2Implementation());
    }
}

abstract contract Initialized is Uninitialized {
    address admin = address(this);

    function setUp() public virtual override {
        super.setUp();
        deployTCAPV2Transparent(admin, admin);
        tCAPV2.grantRole(Roles.ORACLE_SETTER_ROLE, admin);
        tCAPV2.grantRole(Roles.VAULT_ROLE, admin);
    }
}

contract UninitializedTest is Uninitialized {
    function test_InitialState() public {
        assertEq(tCAPV2.totalSupply(), 0);
    }

    function test_RevertsOnInitialization() public {
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        tCAPV2.initialize(address(1));
    }

    function test_Version() public {
        assertEq(tCAPV2.version(), "1.0.0");
    }
}

contract InitializedTest is Initialized {
    error AccessControlUnauthorizedAccount(address account, bytes32 role);

    event Transfer(address indexed from, address indexed to, uint256 value);

    function test_InitialState() public {
        assertEq(tCAPV2.totalSupply(), 0);
    }

    function test_RevertIf_SenderNotVault(address sender) public {
        vm.assume(sender != admin && sender != address(tCAPV2ProxyAdmin));
        vm.expectRevert(abi.encodeWithSelector(AccessControlUnauthorizedAccount.selector, sender, Roles.VAULT_ROLE));
        vm.prank(sender);
        tCAPV2.mint(sender, 100);
        vm.expectRevert(abi.encodeWithSelector(AccessControlUnauthorizedAccount.selector, sender, Roles.VAULT_ROLE));
        vm.prank(sender);
        tCAPV2.burn(sender, 100);
    }

    function test_ShouldBeAbleToMint(address recipient, uint256 amount) public {
        vm.assume(recipient != address(0));
        vm.expectEmit(true, true, false, true);
        emit Transfer(address(0), recipient, amount);
        vm.expectEmit(true, true, false, true);
        emit ITCAPV2.Minted(admin, recipient, amount);
        tCAPV2.mint(recipient, amount);
        assertEq(tCAPV2.balanceOf(recipient), amount);
        assertEq(tCAPV2.totalSupply(), amount);
        assertEq(tCAPV2.mintedAmount(admin), amount);
    }

    function test_RevertIf_BurningMoreThanMinted(address recipient, uint256 mintAmount, uint256 burnAmount) public {
        vm.assume(recipient != address(0));
        mintAmount = bound(mintAmount, 1, type(uint256).max - 2);
        burnAmount = bound(burnAmount, mintAmount + 1, type(uint256).max);
        tCAPV2.mint(address(this), mintAmount);
        tCAPV2.transfer(recipient, mintAmount);
        vm.expectRevert(abi.encodeWithSelector(ITCAPV2.BalanceExceeded.selector, admin));
        tCAPV2.burn(recipient, burnAmount);
    }

    function test_ShouldBeAbleToBurn(address recipient, uint256 mintAmount, uint256 burnAmount) public {
        vm.assume(recipient != address(0));
        mintAmount = bound(mintAmount, 1, type(uint256).max);
        burnAmount = bound(burnAmount, 0, mintAmount);
        tCAPV2.mint(address(this), mintAmount);
        tCAPV2.transfer(recipient, mintAmount);
        vm.expectEmit(true, true, false, true);
        emit Transfer(recipient, address(0), burnAmount);
        vm.expectEmit(true, true, false, true);
        emit ITCAPV2.Burned(admin, recipient, burnAmount);
        tCAPV2.burn(recipient, burnAmount);
        assertEq(tCAPV2.balanceOf(recipient), mintAmount - burnAmount);
        assertEq(tCAPV2.totalSupply(), mintAmount - burnAmount);
        assertEq(tCAPV2.mintedAmount(admin), mintAmount - burnAmount);
    }

    function test_RevertIf_OracleIsInvalid() public {
        MockFeed feed = new MockFeed(1e18);
        MockCollateral collateral = new MockCollateral();
        AggregatedChainlinkOracle oracle = new AggregatedChainlinkOracle(address(feed), address(collateral));
        vm.expectRevert(IOracle.InvalidOracle.selector);
        tCAPV2.setOracle(address(oracle));
    }

    function test_ShouldBeAbleToSetOracle() public {
        // 3T USD * 8 decimals
        MockFeed feed = new MockFeed(3e12 * 1e8);
        TCAPTargetOracle oracle = new TCAPTargetOracle(tCAPV2, address(feed));
        vm.expectEmit(true, true, false, true);
        emit ITCAPV2.OracleUpdated(address(oracle));
        tCAPV2.setOracle(address(oracle));
        assertEq(tCAPV2.oracle(), address(oracle));
        // 3T USD * 18 decimals / divisor
        assertEq(tCAPV2.latestPrice(), 3e12 * 1e18 / Constants.DIVISOR);
    }
}

contract DeployerTest is Test {
    function test_Deployer() public {
        address proxyAdminOwner = makeAddr("proxyAdminOwner");
        address admin = makeAddr("admin");
        AggregatorV3Interface feed = new MockFeed(3e12 * 1e8);
        vm.recordLogs();
        address deployer = address(new TCAPDeployer(proxyAdminOwner, admin, feed));
        Vm.Log[] memory entries = vm.getRecordedLogs();
        TCAPV2 tcap = TCAPV2(address(uint160(uint256(entries[entries.length - 1].topics[1]))));

        address actualProxyAdminOwner =
            ProxyAdmin(address(uint160(uint256(vm.load(address(tcap), hex"b53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103"))))).owner();
        assertEq(actualProxyAdminOwner, proxyAdminOwner, "proxyAdminOwner does not match");

        assertFalse(tcap.hasRole(Roles.ORACLE_SETTER_ROLE, deployer), "deployer should not have oracle setter role");
        assertFalse(tcap.hasRole(Roles.DEFAULT_ADMIN_ROLE, deployer), "deployer should not have default admin role");
        assertTrue(tcap.hasRole(Roles.DEFAULT_ADMIN_ROLE, admin), "admin should have default admin role");
    }
}
