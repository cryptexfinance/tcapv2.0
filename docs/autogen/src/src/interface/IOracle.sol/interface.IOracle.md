# IOracle
[Git Source](https://github.com/cryptexfinance/tcapv2.0/blob/55fee5686407b0eff65f8c90731b3d51888021cf/src/interface/IOracle.sol)

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
function latestPrice(bool checkStaleness) external view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|the latest price of the asset|


## Errors
### InvalidOracle
Should be thrown when the oracle is not valid


```solidity
error InvalidOracle();
```

### StaleOracle
Thrown when the oracle is stale


```solidity
error StaleOracle();
```

