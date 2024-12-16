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
        vault[8453][0x4200000000000000000000000000000000000006] = 0x4F94C14440ef38B7e551CCFB7A2ce4E464E20F14;
        pockets[8453][0x4200000000000000000000000000000000000006] = PocketData({
            admin: 0x570f581D23a2AB09FD1990279D9DB6f5DcE18F4A,
            deployDefault: true,
            deployAave: true,
            aavePool: 0xA238Dd80C259a72e81d7e4664a9801593F98d1c5
        });
        // cbBTC
        vault[8453][0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf] = 0xA6afc2be04a1c2ED8bEC7F924307b6254fAFF750;
        pockets[8453][0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf] = PocketData({
            admin: 0x570f581D23a2AB09FD1990279D9DB6f5DcE18F4A,
            deployDefault: true,
            deployAave: true,
            aavePool: 0xA238Dd80C259a72e81d7e4664a9801593F98d1c5
        });
        // USDC
        vault[8453][0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913] = 0x1857e926BB5e5b12e9275818B03F79cdfd799999;
        pockets[8453][0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913] = PocketData({
            admin: 0x570f581D23a2AB09FD1990279D9DB6f5DcE18F4A,
            deployDefault: true,
            deployAave: true,
            aavePool: 0xA238Dd80C259a72e81d7e4664a9801593F98d1c5
        });
    }
}
