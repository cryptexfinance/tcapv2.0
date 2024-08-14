# AggregatedChainlinkOracle
[Git Source](https://github.com/cryptexfinance/tcapv2.0/blob/34a621b9d7f953a62f8f826356dda361dde059e4/src/oracle/AggregatedChainlinkOracle.sol)

**Inherits:**
[BaseOracleUSD](/src/oracle/BaseOracleUSD.sol/abstract.BaseOracleUSD.md)

*all oracles are priced in USD with 18 decimals*


## State Variables
### feed

```solidity
AggregatorV3Interface public immutable feed;
```


### _decimals

```solidity
uint256 internal immutable _decimals;
```


## Functions
### constructor


```solidity
constructor(address feed_, address token) BaseOracleUSD(token);
```

### latestPrice


```solidity
function latestPrice() public view virtual override returns (uint256);
```

