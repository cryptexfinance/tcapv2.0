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
        vault[8453][0x4200000000000000000000000000000000000006] = address(0); // TODO set after deployment
        pockets[8453][0x4200000000000000000000000000000000000006] = PocketData({
            admin: 0x570f581D23a2AB09FD1990279D9DB6f5DcE18F4A,
            deployDefault: true,
            deployAave: true,
            aavePool: 0xA238Dd80C259a72e81d7e4664a9801593F98d1c5
        });
        // cbBTC
        vault[8453][0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf] = address(0); // TODO set after deployment
        pockets[8453][0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf] = PocketData({
            admin: 0x570f581D23a2AB09FD1990279D9DB6f5DcE18F4A,
            deployDefault: true,
            deployAave: true,
            aavePool: 0xA238Dd80C259a72e81d7e4664a9801593F98d1c5
        });
        // USDC
        vault[8453][0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913] = address(0); // TODO set after deployment
        pockets[8453][0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913] = PocketData({
            admin: 0x570f581D23a2AB09FD1990279D9DB6f5DcE18F4A,
            deployDefault: true,
            deployAave: true,
            aavePool: 0xA238Dd80C259a72e81d7e4664a9801593F98d1c5
        });
    }
}
