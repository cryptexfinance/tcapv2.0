# TCAPTargetOracle
[Git Source](https://github.com/cryptexfinance/tcapv2.0/blob/34a621b9d7f953a62f8f826356dda361dde059e4/src/oracle/TCAPTargetOracle.sol)

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

