# IOracle
[Git Source](https://github.com/cryptexfinance/tcapv2.0/blob/6bc13f590e0d259edfc7844b2201ce75ef760a67/src/interface/IOracle.sol)

Interface that needs to be implemented by all oracles


## Functions
### asset


```solidity
function asset() external view returns (address);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|the address of the asset this oracle is used for|


### latestPrice

*the returned price must have 18 decimals*


```solidity
function latestPrice() external view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|the latest price of the asset|


### assetDecimals

returns the assets of the underlying asset


```solidity
function assetDecimals() external view returns (uint8);
```

## Errors
### InvalidOracle
Should be thrown when the oracle is not valid


```solidity
error InvalidOracle();
```

