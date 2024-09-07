# LiquidationLib
[Git Source](https://github.com/cryptexfinance/tcapv2.0/blob/adb271543417436c1309ef4ed99a33410b5ee7ce/src/lib/LiquidationLib.sol)


## Functions
### healthFactor


```solidity
function healthFactor(uint256 mintAmount, uint256 tcapPrice, uint256 collateralAmount, uint256 collateralPrice, uint8 collateralDecimals)
    internal
    pure
    returns (uint256);
```

### liquidationReward


```solidity
function liquidationReward(uint256 burnAmount, uint256 tcapPrice, uint256 collateralPrice, uint64 liquidationPenalty) internal pure returns (uint256);
```

### tokensRequiredForTargetHealthFactor


```solidity
function tokensRequiredForTargetHealthFactor(
    uint256 targetHealthFactor,
    uint256 mintAmount,
    uint256 tcapPrice,
    uint256 collateralAmount,
    uint256 collateralPrice,
    uint64 liquidationPenalty,
    uint8 collateralDecimals
) internal pure returns (uint256);
```

