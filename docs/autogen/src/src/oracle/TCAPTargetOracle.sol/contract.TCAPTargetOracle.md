# TCAPTargetOracle
[Git Source](https://github.com/cryptexfinance/tcapv2.0/blob/d197f8ef7c2bfcdd8eeb0e4fc546c998a12a18f4/src/oracle/TCAPTargetOracle.sol)

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
function latestPrice() public view virtual override returns (uint256);
```

