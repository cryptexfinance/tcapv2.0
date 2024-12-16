// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Script.sol";
import {VaultDeployParams, Params} from "./deployers/VaultDeployParams.sol";
import {AggregatedChainlinkOracle} from "../src/oracle/AggregatedChainlinkOracle.sol";
import {VaultDeployer, ITCAPV2, IERC20, IPermit2} from "./deployers/VaultDeployer.s.sol";
import "src/Vault.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {TransparentUpgradeableProxy, ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract Deploy is VaultDeployer, VaultDeployParams {
    using stdJson for string;

//    Vault internal vault;
//    ProxyAdmin internal vaultProxyAdmin;
//    address internal vaultImplementation;

    address[] vaultsToDeployTokens =
        [0x4200000000000000000000000000000000000006, 0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf, 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913];

    function run() public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        for (uint256 i = 0; i < vaultsToDeployTokens.length; i++) {
            if (tcap[block.chainid] == address(0)) revert("TCAP address not set");
            address token = vaultsToDeployTokens[i];
            Params memory params = _params[block.chainid][token];
            if (!params.exists) revert("Config for token not found");
            AggregatedChainlinkOracle oracle = new AggregatedChainlinkOracle(params.oracleParams.priceFeed, token, params.oracleParams.heartbeat * 10);

            bytes memory initData = abi.encodeCall(Vault.initialize, (params.admin, params.initialFee, address(oracle), params.feeRecipient, params.liquidationParams));
            vaultImplementation = address(new Vault(ITCAPV2(tcap[block.chainid]), IERC20(token), IPermit2(0x000000000022D473030F116dDEE9F6B43aC78BA3)));
            vault = Vault(address(new TransparentUpgradeableProxy(vaultImplementation, params.admin, initData)));
            vaultProxyAdmin = ProxyAdmin(address(uint160(uint256(vm.load(address(vault), hex"b53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103")))));
            console.log("Collateral address, vault address:", address(IERC20(token)), address(vault));
            console.log("vault address:, proxyadmin address", address(vault), address(vaultProxyAdmin));
        }
        vm.stopBroadcast();

    }
}
