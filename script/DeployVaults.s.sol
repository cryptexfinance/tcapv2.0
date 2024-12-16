// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Script.sol";
import {VaultDeployParams, Params} from "./deployers/VaultDeployParams.sol";
import {AggregatedChainlinkOracle} from "../src/oracle/AggregatedChainlinkOracle.sol";
import {VaultDeployer, ITCAPV2, IERC20, IPermit2} from "./deployers/VaultDeployer.s.sol";

contract Deploy is VaultDeployer, VaultDeployParams {
    using stdJson for string;

    address[] vaultsToDeployTokens =
        [0x4200000000000000000000000000000000000006, 0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf, 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913];

    function run() public {
        for (uint256 i = 0; i < vaultsToDeployTokens.length; i++) {
            if (tcap[block.chainid] == address(0)) revert("TCAP address not set");
            address token = vaultsToDeployTokens[i];
            Params memory params = _params[block.chainid][token];
            if (!params.exists) revert("Config for token not found");
            vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
            AggregatedChainlinkOracle oracle = new AggregatedChainlinkOracle(params.oracleParams.priceFeed, token, params.oracleParams.heartbeat * 10);
            vm.stopBroadcast();
            deployVaultTransparent(
                params.admin,
                ITCAPV2(tcap[block.chainid]),
                IERC20(token),
                IPermit2(0x000000000022D473030F116dDEE9F6B43aC78BA3),
                params.admin,
                params.initialFee,
                address(oracle),
                params.feeRecipient,
                params.liquidationParams
            );
        }

    }
}
