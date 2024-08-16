# BaseOracleUSD
[Git Source](https://github.com/cryptexfinance/tcapv2.0/blob/34a621b9d7f953a62f8f826356dda361dde059e4/src/oracle/BaseOracleUSD.sol)

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
uint256 public immutable assetDecimals;
```


## Functions
### constructor


```solidity
constructor(address token);
```

