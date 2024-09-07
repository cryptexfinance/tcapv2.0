# BaseOracleUSD
[Git Source](https://github.com/cryptexfinance/tcapv2.0/blob/adb271543417436c1309ef4ed99a33410b5ee7ce/src/oracle/BaseOracleUSD.sol)

**Inherits:**
[IOracle](/src/interface/IOracle.sol/interface.IOracle.md)

Base contract that sets the underlying asset and the decimals of that asset for the oracle


## State Variables
### asset

```solidity
address public immutable asset;
```


### assetDecimals

```solidity
uint8 public immutable assetDecimals;
```


## Functions
### constructor


```solidity
constructor(address token);
```

