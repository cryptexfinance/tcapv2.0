// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Script.sol";
import {IPocket, IVault } from "src/interface/pockets/IPocket.sol";
import {Roles} from "src/lib/Constants.sol";
import {TCAPV2, ITCAPV2} from "src/TCAPV2.sol";

contract SetupSystem is Script {
    address admin = 0x6BF125D25cC4d00FAB06C30095f8DCBe2617bBBD;
    address proxyAdmin = 0x570f581D23a2AB09FD1990279D9DB6f5DcE18F4A;
    address wETHVaultAddress = 0x4F94C14440ef38B7e551CCFB7A2ce4E464E20F14;
    address cbBTCVaultAddress = 0xA6afc2be04a1c2ED8bEC7F924307b6254fAFF750;
    address usdcVaultAddress = 0x1857e926BB5e5b12e9275818B03F79cdfd799999;

    TCAPV2 tcapV2 = TCAPV2(0x4e99472385a2522aa292b008Da294a78F420A367);

    IVault wETHVault = IVault(wETHVaultAddress);
    IVault cbBTCVault = IVault(cbBTCVaultAddress);
    IVault usdcVault = IVault(usdcVaultAddress);

    IPocket wETHDefaultPocket = IPocket(0x75E78d6659BBc2c1599464e153607a21947A466B);
    IPocket cbBTCDefaultPocket = IPocket(0x806c81138A52524Ce218E3C6C19873F53334BF94);
    IPocket usdcDefaultPocket = IPocket(0xb0fC91A11d770bD7a6312944199E3a9De85057A3);

    IPocket wETHAavePocket = IPocket(0x134ba1c4E7443fC5c0bE8Ca675DF0bE611bd589C);
    IPocket cbBTCAavePocket = IPocket(0xCf041E8c66785c7BC41284C66b8aDe5A02094a6e);
    IPocket usdcAavePocket = IPocket(0x9a0A963ce5CD1C9e5Ef5df862b42143E82f6412C);

    function run() external {
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
