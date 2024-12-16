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
        tcap[8453] = 0x4e99472385a2522aa292b008Da294a78F420A367;
        // WETH
        _params[8453][0x4200000000000000000000000000000000000006] = Params({
            exists: true,
            oracleParams: OracleParams({priceFeed: 0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70, heartbeat: 1200}),
            admin: 0x570f581D23a2AB09FD1990279D9DB6f5DcE18F4A,
            initialFee: 0,
            feeRecipient: 0x6BF125D25cC4d00FAB06C30095f8DCBe2617bBBD,
            liquidationParams: IVault.LiquidationParams({threshold: 1.3e18, penalty: 0.1e18, minHealthFactor: 0.05e18, maxHealthFactor: 0.1e18})
        });
        // cbBTC
        _params[8453][0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf] = Params({
            exists: true,
            oracleParams: OracleParams({priceFeed: 0x07DA0E54543a844a80ABE69c8A12F22B3aA59f9D, heartbeat: 1200}),
            admin: 0x570f581D23a2AB09FD1990279D9DB6f5DcE18F4A,
            initialFee: 0,
            feeRecipient: 0x6BF125D25cC4d00FAB06C30095f8DCBe2617bBBD,
            liquidationParams: IVault.LiquidationParams({threshold: 1.3e18, penalty: 0.1e18, minHealthFactor: 0.05e18, maxHealthFactor: 0.1e18})
        });
        // USDC
        _params[8453][0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913] = Params({
            exists: true,
            oracleParams: OracleParams({priceFeed: 0x7e860098F58bBFC8648a4311b374B1D669a2bc6B, heartbeat: 86_400}),
            admin: 0x570f581D23a2AB09FD1990279D9DB6f5DcE18F4A,
            initialFee: 0,
            feeRecipient: 0x6BF125D25cC4d00FAB06C30095f8DCBe2617bBBD,
            liquidationParams: IVault.LiquidationParams({threshold: 1.3e18, penalty: 0.1e18, minHealthFactor: 0.05e18, maxHealthFactor: 0.1e18})
        });
    }
}
