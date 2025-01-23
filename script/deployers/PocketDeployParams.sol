// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct PocketData {
    address admin;
    bool deployDefault;
    bool deployAave;
    address aavePool;
}

contract PocketDeployParams {
    mapping(uint256 chainId => mapping(address token => address)) internal vault;
    mapping(uint256 chainId => mapping(address token => PocketData)) internal pockets;

    constructor() {
        // WETH
        vault[84532][0x4200000000000000000000000000000000000006] = 0x678295F27e8523cd437326DB9D2875aD7B6B991d;
        pockets[84532][0x4200000000000000000000000000000000000006] = PocketData({
            admin: 0x30Abf2e1ac3A52c8c3F99078d1D52667d656C84B,
            deployDefault: true,
            deployAave: true,
            aavePool: 0x07eA79F68B2B3df564D0A34F8e19D9B1e339814b
        });
        // cbBTC
//        vault[8453][0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf] = 0xA6afc2be04a1c2ED8bEC7F924307b6254fAFF750;
//        pockets[8453][0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf] = PocketData({
//            admin: 0x570f581D23a2AB09FD1990279D9DB6f5DcE18F4A,
//            deployDefault: true,
//            deployAave: true,
//            aavePool: 0xA238Dd80C259a72e81d7e4664a9801593F98d1c5
//        });
        // USDC
        vault[84532][0x036CbD53842c5426634e7929541eC2318f3dCF7e] = 0x62beb4f28f70cF7E4d5BCa54e86851b12AeF2d48;
        pockets[84532][0x036CbD53842c5426634e7929541eC2318f3dCF7e] = PocketData({
            admin: 0x30Abf2e1ac3A52c8c3F99078d1D52667d656C84B,
            deployDefault: true,
            deployAave: true,
            aavePool: 0x07eA79F68B2B3df564D0A34F8e19D9B1e339814b
        });
    }
}
