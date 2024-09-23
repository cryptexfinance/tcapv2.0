# LiquidationLib
[Git Source](https://github.com/cryptexfinance/tcapv2.0/blob/7c3050a56e3f1bad1a100f3e506744d0c71a8807/src/lib/LiquidationLib.sol)


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
function liquidationReward(uint256 burnAmount, uint256 tcapPrice, uint256 collateralPrice, uint64 liquidationPenalty, uint8 collateralDecimals)
    internal
    pure
    returns (uint256);
```

### tokensRequiredForTargetHealthFactor


```solidity
function tokensRequiredForTargetHealthFactor(uint256 currentHealthFactor, uint256 targetHealthFactor, uint256 mintAmount, uint64 liquidationPenalty)
    internal
    pure
    returns (uint256);
```

