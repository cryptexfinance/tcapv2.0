# TCAPTargetOracle
[Git Source](https://github.com/cryptexfinance/tcapv2.0/blob/55fee5686407b0eff65f8c90731b3d51888021cf/src/oracle/TCAPTargetOracle.sol)

**Inherits:**
[AggregatedChainlinkOracle](/src/oracle/AggregatedChainlinkOracle.sol/contract.AggregatedChainlinkOracle.md)

*Returns the target price of the TCAP token*


## Functions
### constructor


```solidity
constructor(ITCAPV2 tcap, address feed_) AggregatedChainlinkOracle(feed_, address(tcap));
```

### latestPrice


```solidity
function latestPrice(bool checkStaleness) public view virtual override returns (uint256);
```

