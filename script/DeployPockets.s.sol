// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Script.sol";
import {PocketDeployParams, PocketData} from "./deployers/PocketDeployParams.sol";
import {AggregatedChainlinkOracle} from "../src/oracle/AggregatedChainlinkOracle.sol";
import {DefaultPocketDeployer} from "./deployers/DefaultPocketDeployer.s.sol";
import {AaveV3PocketDeployer} from "./deployers/AaveV3PocketDeployer.s.sol";

contract Deploy is DefaultPocketDeployer, AaveV3PocketDeployer, PocketDeployParams {
    using stdJson for string;

    address[] pocketsToDeployForTokens =
        [0x4200000000000000000000000000000000000006, 0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf, 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913];

    function run() public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        for (uint256 i = 0; i < pocketsToDeployForTokens.length; i++) {
            address token = pocketsToDeployForTokens[i];
            address vault_ = vault[block.chainid][token];
            if (vault_ == address(0)) revert("Vault address not set");
            PocketData memory params = pockets[block.chainid][token];
            if (params.deployDefault) {
                deployDefaultPocketTransparent(params.admin, vault_, token);
            }
            if (params.deployAave) {
                if (params.aavePool == address(0)) revert("Aave pool address not set");
                deployAaveV3PocketTransparent(params.admin, vault_, token, params.aavePool);
            }
        }
        vm.stopBroadcast();
    }
}
