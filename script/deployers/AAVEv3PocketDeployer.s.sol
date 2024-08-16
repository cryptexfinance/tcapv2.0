// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

////////////////////////////////////////////////////
// AUTOGENERATED - DO NOT EDIT THIS FILE DIRECTLY //
////////////////////////////////////////////////////

import "forge-std/Script.sol";

import "src/pockets/AAVEv3Pocket.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {TransparentUpgradeableProxy, ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

abstract contract AAVEv3PocketDeployer is Script {
    AAVEv3Pocket internal aAVEv3Pocket;
    ProxyAdmin internal aAVEv3PocketProxyAdmin;
    address internal aAVEv3PocketImplementation;

    function deployAAVEv3PocketTransparent(address proxyAdminOwner, address vault_, address underlyingToken_, address overlyingToken_, address aavePool)
        internal
        returns (address implementation, address proxyAdmin, address proxy)
    {
        bytes memory initData = abi.encodeCall(BasePocket.initialize, ());

        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        aAVEv3PocketImplementation = address(new AAVEv3Pocket(vault_, underlyingToken_, overlyingToken_, aavePool));
        aAVEv3Pocket = AAVEv3Pocket(address(new TransparentUpgradeableProxy(aAVEv3PocketImplementation, proxyAdminOwner, initData)));

        vm.stopBroadcast();

        aAVEv3PocketProxyAdmin =
            ProxyAdmin(address(uint160(uint256(vm.load(address(aAVEv3Pocket), hex"b53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103")))));

        return (aAVEv3PocketImplementation, address(aAVEv3PocketProxyAdmin), address(aAVEv3Pocket));
    }

    function deployAAVEv3PocketImplementation(address vault_, address underlyingToken_, address overlyingToken_, address aavePool)
        internal
        returns (address implementation)
    {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        implementation = address(new AAVEv3Pocket(vault_, underlyingToken_, overlyingToken_, aavePool));
        vm.stopBroadcast();
    }
}
