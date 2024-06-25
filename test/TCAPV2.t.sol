// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import "test/util/TestHelpers.sol";

import "script/deployers/TCAPV2Deployer.s.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract Uninitialized is Test, TestHelpers, TCAPV2Deployer {
    function setUp() public virtual {
        tCAPV2 = TCAPV2(deployTCAPV2Implementation());
    }
}

abstract contract Initialized is Uninitialized {
    address admin = makeAddr("admin");

    function setUp() public virtual override {
        super.setUp();
        deployTCAPV2Transparent(admin, admin);
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
}

contract InitializedTest is Initialized {
    function test_InitialState() public {
        assertEq(tCAPV2.totalSupply(), 0);
    }
}
