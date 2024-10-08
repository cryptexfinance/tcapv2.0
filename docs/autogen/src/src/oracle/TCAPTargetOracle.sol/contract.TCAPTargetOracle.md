# TCAPTargetOracle
[Git Source](https://github.com/cryptexfinance/tcapv2.0/blob/6fb291c7e6c372c076c9cd314a2348fadd32af09/src/oracle/TCAPTargetOracle.sol)

**Inherits:**
[AggregatedChainlinkOracle](/src/oracle/AggregatedChainlinkOracle.sol/contract.AggregatedChainlinkOracle.md)

*Returns the target price of the TCAP token*


## Functions
### constructor


```solidity
constructor(ITCAPV2 tcap, address feed_, uint256 stalenessDelay_) AggregatedChainlinkOracle(feed_, address(tcap), stalenessDelay_);
```

### latestPrice


```solidity
function latestPrice(bool checkStaleness) public view virtual override returns (uint256);
```

