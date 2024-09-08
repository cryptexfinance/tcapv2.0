# TCAPTargetOracle
[Git Source](https://github.com/cryptexfinance/tcapv2.0/blob/6bc13f590e0d259edfc7844b2201ce75ef760a67/src/oracle/TCAPTargetOracle.sol)

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
constructor(ITCAPV2 tcap, address feed) AggregatedChainlinkOracle(feed, address(tcap));
```

### latestPrice


```solidity
function latestPrice() public view virtual override returns (uint256);
```

