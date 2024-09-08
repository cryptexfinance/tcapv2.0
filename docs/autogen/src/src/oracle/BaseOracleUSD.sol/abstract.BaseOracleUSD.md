# BaseOracleUSD
[Git Source](https://github.com/cryptexfinance/tcapv2.0/blob/6bc13f590e0d259edfc7844b2201ce75ef760a67/src/oracle/BaseOracleUSD.sol)

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

