# BaseOracleUSD
[Git Source](https://github.com/cryptexfinance/tcapv2.0/blob/7c3050a56e3f1bad1a100f3e506744d0c71a8807/src/oracle/BaseOracleUSD.sol)

**Inherits:**
[IOracle](/src/interface/IOracle.sol/interface.IOracle.md)

Base contract that sets the underlying asset and the decimals of that asset for the oracle


## State Variables
### asset

```solidity
address public immutable asset;
```


## Functions
### constructor


```solidity
constructor(address token);
```

