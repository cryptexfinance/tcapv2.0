// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IVault} from "../../src/Vault.sol";

struct OracleParams {
    address priceFeed;
    uint256 heartbeat;
}

struct Params {
    bool exists;
    OracleParams oracleParams;
    address admin;
    uint16 initialFee;
    address feeRecipient;
    IVault.LiquidationParams liquidationParams;
}

contract VaultDeployParams {
    mapping(uint256 chainId => address) internal tcap;
    mapping(uint256 chainId => mapping(address token => Params)) internal _params;

    constructor() {
        // Base
        tcap[84532] = 0x18a849b56a97B52CA5F1B0f66F3cf7bC4Bf0ECe2;
        // WETH
        _params[84532][0x4200000000000000000000000000000000000006] = Params({
            exists: true,
            oracleParams: OracleParams({priceFeed: 0x4aDC67696bA383F43DD60A9e78F2C97Fbbfc7cb1, heartbeat: 1200}),
            admin: 0x30Abf2e1ac3A52c8c3F99078d1D52667d656C84B,
            initialFee: 0,
            feeRecipient: 0x30Abf2e1ac3A52c8c3F99078d1D52667d656C84B,
            liquidationParams: IVault.LiquidationParams({threshold: 1.3e18, penalty: 0.1e18, minHealthFactor: 0.05e18, maxHealthFactor: 0.1e18})
        });
        // cbBTC
//        _params[8453][0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf] = Params({
//            exists: true,
//            oracleParams: OracleParams({priceFeed: 0x07DA0E54543a844a80ABE69c8A12F22B3aA59f9D, heartbeat: 1200}),
//            admin: 0x570f581D23a2AB09FD1990279D9DB6f5DcE18F4A,
//            initialFee: 0,
//            feeRecipient: 0x6BF125D25cC4d00FAB06C30095f8DCBe2617bBBD,
//            liquidationParams: IVault.LiquidationParams({threshold: 1.3e18, penalty: 0.1e18, minHealthFactor: 0.05e18, maxHealthFactor: 0.1e18})
//        });
        // USDC
        _params[84532][0x036CbD53842c5426634e7929541eC2318f3dCF7e] = Params({
            exists: true,
            oracleParams: OracleParams({priceFeed: 0xd30e2101a97dcbAeBCBC04F14C3f624E67A35165, heartbeat: 86_400}),
            admin: 0x30Abf2e1ac3A52c8c3F99078d1D52667d656C84B,
            initialFee: 0,
            feeRecipient: 0x30Abf2e1ac3A52c8c3F99078d1D52667d656C84B,
            liquidationParams: IVault.LiquidationParams({threshold: 1.3e18, penalty: 0.1e18, minHealthFactor: 0.05e18, maxHealthFactor: 0.1e18})
        });
    }
}
