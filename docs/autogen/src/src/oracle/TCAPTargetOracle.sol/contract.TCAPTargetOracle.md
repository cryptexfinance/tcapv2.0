# TCAPTargetOracle
[Git Source](https://github.com/cryptexfinance/tcapv2.0/blob/adb271543417436c1309ef4ed99a33410b5ee7ce/src/oracle/TCAPTargetOracle.sol)

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

