# AggregatedChainlinkOracle
[Git Source](https://github.com/cryptexfinance/tcapv2.0/blob/6fb291c7e6c372c076c9cd314a2348fadd32af09/src/oracle/AggregatedChainlinkOracle.sol)

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


### stalenessDelay

```solidity
uint256 public immutable stalenessDelay;
```


## Functions
### constructor

*the staleness delay should be set relative to the heartbeat of the feed*


```solidity
constructor(address feed_, address token, uint256 stalenessDelay_) BaseOracleUSD(token);
```

### latestPrice


```solidity
function latestPrice(bool checkStaleness) public view virtual override returns (uint256);
```

