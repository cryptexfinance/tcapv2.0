// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Constants {
    uint64 internal constant MIN_LIQUIDATION_THRESHOLD = 1e18;
    uint64 internal constant MAX_LIQUIDATION_THRESHOLD = 3e18;
    uint64 internal constant MAX_LIQUIDATION_PENALTY = 0.5e18;
    uint64 internal constant MIN_POST_LIQUIDATION_HEALTH_FACTOR = 1;
    uint64 internal constant MAX_POST_LIQUIDATION_HEALTH_FACTOR = 1e18;
    uint256 internal constant MAX_FEE = 10_000; // 100%
    uint8 internal constant TCAP_DECIMALS = 18;
    uint256 internal constant DIVISOR = 1e10;
    /// @dev multiply pocket shares with a decimal offset to mitigate inflation attack
    uint256 internal constant DECIMAL_OFFSET = 1e6;
}

library Roles {
    bytes32 internal constant DEFAULT_ADMIN_ROLE = 0x00;
    // keccak256("VAULT_ROLE")
    bytes32 internal constant VAULT_ROLE = 0x31e0210044b4f6757ce6aa31f9c6e8d4896d24a755014887391a926c5224d959;
    // keccak256("ORACLE_SETTER_ROLE")
    bytes32 internal constant ORACLE_SETTER_ROLE = 0x7b6588f378264a748ba8c75a8b168bb7b5ddca703dafa393fd0b4579f5b784b0;
    // keccak256("POCKET_SETTER_ROLE")
    bytes32 public constant POCKET_SETTER_ROLE = 0xcbd69888d9fba90fe49a0c7a1d66c35e381e4ebf3a66968c85c5beacc25db59a;
    // keccak256("FEE_SETTER_ROLE")
    bytes32 public constant FEE_SETTER_ROLE = 0xe6ad9a47fbda1dc18de1eb5eeb7d935e5e81b4748f3cfc61e233e64f88182060;
    // keccak256("LIQUIDATION_SETTER_ROLE")
    bytes32 public constant LIQUIDATION_SETTER_ROLE = 0xba474fc2b8347e255f10252fdae69399bac572751768da2e97a282acc34401ea;
}
