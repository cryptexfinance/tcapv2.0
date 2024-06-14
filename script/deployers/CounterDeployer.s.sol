// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

////////////////////////////////////////////////////
// AUTOGENERATED - DO NOT EDIT THIS FILE DIRECTLY //
////////////////////////////////////////////////////

import "forge-std/Script.sol";

import "src/Counter.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {TransparentUpgradeableProxy, ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

abstract contract CounterDeployer is Script {
    Counter internal counter;
    ProxyAdmin internal counterProxyAdmin;
    address internal counterImplementation;

    function deployCounterTransparent(address proxyAdminOwner, uint256 initialNumber)
        internal
        returns (address implementation, address proxyAdmin, address proxy)
    {
        bytes memory initData = abi.encodeCall(Counter.initialize, (initialNumber));

        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        counterImplementation = address(new Counter());
        counter = Counter(address(new TransparentUpgradeableProxy(counterImplementation, proxyAdminOwner, initData)));

        vm.stopBroadcast();

        counterProxyAdmin =
            ProxyAdmin(address(uint160(uint256(vm.load(address(counter), hex"b53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103")))));

        return (counterImplementation, address(counterProxyAdmin), address(counter));
    }

    function deployCounterImplementation() internal returns (address implementation) {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        implementation = address(new Counter());
        vm.stopBroadcast();
    }
}
