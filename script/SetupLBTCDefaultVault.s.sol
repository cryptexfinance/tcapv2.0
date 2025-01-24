// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Script.sol";
import {IPocket, IVault } from "src/interface/pockets/IPocket.sol";
import {Roles} from "src/lib/Constants.sol";
import {TCAPV2, ITCAPV2} from "src/TCAPV2.sol";

contract SetupSystem is Script {
    address admin = 0x6BF125D25cC4d00FAB06C30095f8DCBe2617bBBD;
    address proxyAdmin = 0x570f581D23a2AB09FD1990279D9DB6f5DcE18F4A;
    address LBTCVaultAddress = 0xD29D6E24946a8e9B55797F5A4EF34EEB0E73a15A;

    TCAPV2 tcapV2 = TCAPV2(0x4e99472385a2522aa292b008Da294a78F420A367);

    IVault LBTCVault = IVault(LBTCVaultAddress);

    IPocket LBTCDefaultPocket = IPocket(0x447B9948464593e1235601157063c495b115e02e);


    function run() external {
        vm.startBroadcast(vm.envUint("PROXY_ADMIN_PRIVATE_KEY"));

//        tcapV2.grantRole(Roles.VAULT_ROLE, LBTCVaultAddress);

        LBTCVault.grantRole(Roles.POCKET_SETTER_ROLE, proxyAdmin);
        LBTCVault.grantRole(Roles.POCKET_SETTER_ROLE, admin);
        LBTCVault.grantRole(Roles.FEE_SETTER_ROLE, admin);
        LBTCVault.grantRole(Roles.LIQUIDATION_SETTER_ROLE, admin);

        LBTCVault.addPocket(LBTCDefaultPocket);

        LBTCVault.revokeRole(Roles.POCKET_SETTER_ROLE, proxyAdmin);

        LBTCVault.revokeRole(Roles.DEFAULT_ADMIN_ROLE, proxyAdmin);

        vm.stopBroadcast();
    }
}
