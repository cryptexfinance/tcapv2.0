# Multicall
[Git Source](https://github.com/cryptexfinance/tcapv2.0/blob/3ef6bd16edededb3779ffafd1e769c1b67e04d32/src/lib/Multicall.sol)

**Inherits:**
[IMulticall](/src/interface/IMulticall.sol/interface.IMulticall.md)

Enables calling multiple methods in a single call to the contract


## Functions
### multicall

Call multiple functions in the current contract and return the data from all of them if they all succeed

*The `msg.value` should not be trusted for any method callable from multicall.*


```solidity
function multicall(bytes[] calldata data) external override returns (bytes[] memory results);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`data`|`bytes[]`|The encoded function data for each of the calls to make to this contract|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`results`|`bytes[]`|The results from each of the calls passed in via data|


