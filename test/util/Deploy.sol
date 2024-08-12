// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Vm} from "forge-std/Test.sol";
import {IPermit2} from "permit2/src/interfaces/IPermit2.sol";

library Deploy {
    Vm private constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    function permit2() internal returns (IPermit2 permit2_) {
        bytes memory bytecode = vm.readFileBinary("test/bin/permit2.bytecode");
        assembly {
            permit2_ := create(0, add(bytecode, 0x20), mload(bytecode))
        }
    }
}
