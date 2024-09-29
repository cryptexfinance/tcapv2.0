# AggregatedChainlinkOracle
[Git Source](https://github.com/cryptexfinance/tcapv2.0/blob/55fee5686407b0eff65f8c90731b3d51888021cf/src/oracle/AggregatedChainlinkOracle.sol)

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
function latestPrice(bool checkStaleness) public view virtual override returns (uint256);
```

