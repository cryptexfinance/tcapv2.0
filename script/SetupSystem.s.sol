// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Script.sol";
import {IPocket, IVault } from "src/interface/pockets/IPocket.sol";
import {Roles} from "src/lib/Constants.sol";
import {TCAPV2, ITCAPV2} from "src/TCAPV2.sol";

contract SetupSystem is Script {

    function run() external {
        address admin = 0x6BF125D25cC4d00FAB06C30095f8DCBe2617bBBD;
        address proxyAdmin = 0x570f581D23a2AB09FD1990279D9DB6f5DcE18F4A;
        address wETHVaultAddress = address(0); // TODO: set  address
        address cbBTCVaultAddress = address(0); // TODO: set address
        address usdcVaultAddress = address(0); // TODO: set address

        TCAPV2 tcapV2 = TCAPV2(address(0)); // TODO: set TCAP address

        IVault wETHVault = IVault(wETHVaultAddress);
        IVault cbBTCVault = IVault(cbBTCVaultAddress);
        IVault usdcVault = IVault(usdcVaultAddress);

        IPocket wETHDefaultPocket = IPocket(address(0)); // TODO: set address
        IPocket cbBTCDefaultPocket = IPocket(address(0)); // TODO: set address
        IPocket usdcDefaultPocket = IPocket(address(0)); // TODO: set address

        IPocket wETHAavePocket = IPocket(address(0)); // TODO: set address
        IPocket cbBTCAavePocket = IPocket(address(0)); // TODO: set address
        IPocket usdcAavePocket = IPocket(address(0)); // TODO: set address

        vm.startBroadcast(vm.envUint("PROXY_ADMIN_PRIVATE_KEY"));

        tcapV2.grantRole(Roles.VAULT_ROLE, wETHVaultAddress);
        tcapV2.grantRole(Roles.VAULT_ROLE, cbBTCVaultAddress);
        tcapV2.grantRole(Roles.VAULT_ROLE, usdcVaultAddress);

        wETHVault.grantRole(Roles.POCKET_SETTER_ROLE, proxyAdmin);
        wETHVault.grantRole(Roles.POCKET_SETTER_ROLE, admin);
        wETHVault.grantRole(Roles.FEE_SETTER_ROLE, admin);
        wETHVault.grantRole(Roles.LIQUIDATION_SETTER_ROLE, admin);

        cbBTCVault.grantRole(Roles.POCKET_SETTER_ROLE, proxyAdmin);
        cbBTCVault.grantRole(Roles.POCKET_SETTER_ROLE, admin);
        cbBTCVault.grantRole(Roles.FEE_SETTER_ROLE, admin);
        cbBTCVault.grantRole(Roles.LIQUIDATION_SETTER_ROLE, admin);

        usdcVault.grantRole(Roles.POCKET_SETTER_ROLE, proxyAdmin);
        usdcVault.grantRole(Roles.POCKET_SETTER_ROLE, admin);
        usdcVault.grantRole(Roles.FEE_SETTER_ROLE, admin);
        usdcVault.grantRole(Roles.LIQUIDATION_SETTER_ROLE, admin);

        wETHVault.addPocket(wETHDefaultPocket);
        wETHVault.addPocket(wETHAavePocket);

        cbBTCVault.addPocket(cbBTCDefaultPocket);
        cbBTCVault.addPocket(cbBTCAavePocket);

        usdcVault.addPocket(usdcDefaultPocket);
        usdcVault.addPocket(usdcAavePocket);

        wETHVault.revokeRole(Roles.POCKET_SETTER_ROLE, proxyAdmin);
        cbBTCVault.revokeRole(Roles.POCKET_SETTER_ROLE, proxyAdmin);
        usdcVault.revokeRole(Roles.POCKET_SETTER_ROLE, proxyAdmin);

        wETHVault.revokeRole(Roles.DEFAULT_ADMIN_ROLE, proxyAdmin);
        cbBTCVault.revokeRole(Roles.DEFAULT_ADMIN_ROLE, proxyAdmin);
        usdcVault.revokeRole(Roles.DEFAULT_ADMIN_ROLE, proxyAdmin);
        tcapV2.revokeRole(Roles.DEFAULT_ADMIN_ROLE, proxyAdmin);

        vm.stopBroadcast();
    }
}
