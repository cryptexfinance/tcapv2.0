// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Script.sol";
import {PocketDeployParams, PocketData} from "./deployers/PocketDeployParams.sol";
import {AggregatedChainlinkOracle} from "../src/oracle/AggregatedChainlinkOracle.sol";
import {DefaultPocketDeployer} from "./deployers/DefaultPocketDeployer.s.sol";
import {AaveV3PocketDeployer} from "./deployers/AaveV3PocketDeployer.s.sol";
import "src/pockets/DefaultPocket.sol";
import "src/pockets/AaveV3Pocket.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {TransparentUpgradeableProxy, ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract Deploy is DefaultPocketDeployer, AaveV3PocketDeployer, PocketDeployParams {
    using stdJson for string;

    address[] pocketsToDeployForTokens =
        [0xecAc9C5F704e954931349Da37F60E39f515c11c1];

    function run() public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        for (uint256 i = 0; i < pocketsToDeployForTokens.length; i++) {
            address token = pocketsToDeployForTokens[i];
            address vault_ = vault[block.chainid][token];
            if (vault_ == address(0)) revert("Vault address not set");
            PocketData memory params = pockets[block.chainid][token];
            if (params.deployDefault) {

                bytes memory initData = abi.encodeCall(DefaultPocket.initialize, ());
                defaultPocketImplementation = address(new DefaultPocket(vault_, token));
                defaultPocket = DefaultPocket(address(new TransparentUpgradeableProxy(defaultPocketImplementation, params.admin, initData)));
                defaultPocketProxyAdmin =
                    ProxyAdmin(address(uint160(uint256(vm.load(address(defaultPocket), hex"b53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103")))));
                console.log("Collateral address, default pocket address:", address(token), address(defaultPocket));
                console.log("pocket address, ProxyAdmin address:", address(defaultPocket), address(defaultPocketProxyAdmin));

            }
            if (params.deployAave) {
                if (params.aavePool == address(0)) revert("Aave pool address not set");

                bytes memory initData = abi.encodeCall(AaveV3Pocket.initialize, ());
                aaveV3PocketImplementation = address(new AaveV3Pocket(vault_, token, params.aavePool));
                aaveV3Pocket = AaveV3Pocket(address(new TransparentUpgradeableProxy(aaveV3PocketImplementation, params.admin, initData)));
                aaveV3PocketProxyAdmin =
                    ProxyAdmin(address(uint160(uint256(vm.load(address(aaveV3Pocket), hex"b53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103")))));
                console.log("Collateral address, aave pocket address:", address(token), address(aaveV3Pocket));
                console.log("aave address, ProxyAdmin address:", address(aaveV3Pocket), address(defaultPocketProxyAdmin));

            }
        }
        vm.stopBroadcast();
    }
}
