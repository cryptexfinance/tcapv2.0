// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

////////////////////////////////////////////////////
// AUTOGENERATED - DO NOT EDIT THIS FILE DIRECTLY //
////////////////////////////////////////////////////

import "forge-std/Script.sol";

import "src/pockets/DefaultPocket.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {TransparentUpgradeableProxy, ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

abstract contract DefaultPocketDeployer is Script {
    DefaultPocket internal defaultPocket;
    ProxyAdmin internal defaultPocketProxyAdmin;
    address internal defaultPocketImplementation;

    function deployDefaultPocketTransparent(address proxyAdminOwner, address vault_, address underlyingToken_)
        internal
        returns (address implementation, address proxyAdmin, address proxy)
    {
        bytes memory initData = abi.encodeCall(DefaultPocket.initialize, ());

        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        defaultPocketImplementation = address(new DefaultPocket(vault_, underlyingToken_));
        defaultPocket = DefaultPocket(address(new TransparentUpgradeableProxy(defaultPocketImplementation, proxyAdminOwner, initData)));

        vm.stopBroadcast();

        defaultPocketProxyAdmin =
            ProxyAdmin(address(uint160(uint256(vm.load(address(defaultPocket), hex"b53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103")))));

        return (defaultPocketImplementation, address(defaultPocketProxyAdmin), address(defaultPocket));
    }

    function deployDefaultPocketImplementation(address vault_, address underlyingToken_) internal returns (address implementation) {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        implementation = address(new DefaultPocket(vault_, underlyingToken_));
        vm.stopBroadcast();
    }
}
