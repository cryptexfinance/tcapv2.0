// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Script.sol";
import {IPocket, IVault } from "src/interface/pockets/IPocket.sol";
import {Roles} from "src/lib/Constants.sol";
import {TCAPV2, ITCAPV2} from "src/TCAPV2.sol";

contract SetupSystem is Script {
    address admin = 0x30Abf2e1ac3A52c8c3F99078d1D52667d656C84B;
    address proxyAdmin = 0x570f581D23a2AB09FD1990279D9DB6f5DcE18F4A;
    address wETHVaultAddress = 0x678295F27e8523cd437326DB9D2875aD7B6B991d;
//    address cbBTCVaultAddress = 0xA6afc2be04a1c2ED8bEC7F924307b6254fAFF750;
    address usdcVaultAddress = 0x62beb4f28f70cF7E4d5BCa54e86851b12AeF2d48;

    TCAPV2 tcapV2 = TCAPV2(0x18a849b56a97B52CA5F1B0f66F3cf7bC4Bf0ECe2);

    IVault wETHVault = IVault(wETHVaultAddress);
//    IVault cbBTCVault = IVault(cbBTCVaultAddress);
    IVault usdcVault = IVault(usdcVaultAddress);

    IPocket wETHDefaultPocket = IPocket(0x8E89Ac6a61C3945f60a17a1B03c77c3F5e0fcaAE);
//    IPocket cbBTCDefaultPocket = IPocket(0x806c81138A52524Ce218E3C6C19873F53334BF94);
    IPocket usdcDefaultPocket = IPocket(0x57285063Bf804df7f163805D97FcE91Bac52f5E2);

    IPocket wETHAavePocket = IPocket(0x415A187e741564d3EE4aCa4E31a003064c0a4b9f);
//    IPocket cbBTCAavePocket = IPocket(0xCf041E8c66785c7BC41284C66b8aDe5A02094a6e);
    IPocket usdcAavePocket = IPocket(0xAF56c4266397d87EC2A04269484f50F42EB650CD);

    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        tcapV2.grantRole(Roles.VAULT_ROLE, wETHVaultAddress);
//        tcapV2.grantRole(Roles.VAULT_ROLE, cbBTCVaultAddress);
        tcapV2.grantRole(Roles.VAULT_ROLE, usdcVaultAddress);

//        wETHVault.grantRole(Roles.POCKET_SETTER_ROLE, proxyAdmin);
        wETHVault.grantRole(Roles.POCKET_SETTER_ROLE, admin);
        wETHVault.grantRole(Roles.FEE_SETTER_ROLE, admin);
        wETHVault.grantRole(Roles.LIQUIDATION_SETTER_ROLE, admin);

//        cbBTCVault.grantRole(Roles.POCKET_SETTER_ROLE, proxyAdmin);
//        cbBTCVault.grantRole(Roles.POCKET_SETTER_ROLE, admin);
//        cbBTCVault.grantRole(Roles.FEE_SETTER_ROLE, admin);
//        cbBTCVault.grantRole(Roles.LIQUIDATION_SETTER_ROLE, admin);

//        usdcVault.grantRole(Roles.POCKET_SETTER_ROLE, proxyAdmin);
        usdcVault.grantRole(Roles.POCKET_SETTER_ROLE, admin);
        usdcVault.grantRole(Roles.FEE_SETTER_ROLE, admin);
        usdcVault.grantRole(Roles.LIQUIDATION_SETTER_ROLE, admin);

        wETHVault.addPocket(wETHDefaultPocket);
        wETHVault.addPocket(wETHAavePocket);

//        cbBTCVault.addPocket(cbBTCDefaultPocket);
//        cbBTCVault.addPocket(cbBTCAavePocket);

        usdcVault.addPocket(usdcDefaultPocket);
        usdcVault.addPocket(usdcAavePocket);

//        wETHVault.revokeRole(Roles.POCKET_SETTER_ROLE, proxyAdmin);
//        cbBTCVault.revokeRole(Roles.POCKET_SETTER_ROLE, proxyAdmin);
//        usdcVault.revokeRole(Roles.POCKET_SETTER_ROLE, proxyAdmin);
//
//        wETHVault.revokeRole(Roles.DEFAULT_ADMIN_ROLE, proxyAdmin);
//        cbBTCVault.revokeRole(Roles.DEFAULT_ADMIN_ROLE, proxyAdmin);
//        usdcVault.revokeRole(Roles.DEFAULT_ADMIN_ROLE, proxyAdmin);
//        tcapV2.revokeRole(Roles.DEFAULT_ADMIN_ROLE, proxyAdmin);

        vm.stopBroadcast();
    }
}
