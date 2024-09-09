# TCAPTargetOracle
[Git Source](https://github.com/cryptexfinance/tcapv2.0/blob/6715a13c6e4abbc7ab93ee610fd231d4c1654bde/src/oracle/TCAPTargetOracle.sol)

**Inherits:**
[AggregatedChainlinkOracle](/src/oracle/AggregatedChainlinkOracle.sol/contract.AggregatedChainlinkOracle.md)

*Returns the target price of the TCAP token*


## State Variables
### DIVISOR

```solidity
uint256 private immutable DIVISOR;
```


## Functions
### constructor


```solidity
constructor(ITCAPV2 tcap, address feed_) AggregatedChainlinkOracle(feed_, address(tcap));
```

### latestPrice


```solidity
function latestPrice() public view virtual override returns (uint256);
```

