# AggregatedChainlinkOracle
[Git Source](https://github.com/cryptexfinance/tcapv2.0/blob/6bc13f590e0d259edfc7844b2201ce75ef760a67/src/oracle/AggregatedChainlinkOracle.sol)

**Inherits:**
[BaseOracleUSD](/src/oracle/BaseOracleUSD.sol/abstract.BaseOracleUSD.md)

*all oracles are priced in USD with 18 decimals*


## State Variables
### feed

```solidity
AggregatorV3Interface public immutable feed;
```


### feedDecimals

```solidity
uint256 public immutable feedDecimals;
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

