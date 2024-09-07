# ITCAPV2
[Git Source](https://github.com/cryptexfinance/tcapv2.0/blob/adb271543417436c1309ef4ed99a33410b5ee7ce/src/interface/ITCAPV2.sol)

**Inherits:**
IERC20, IAccessControl, [IVersioned](/src/interface/IVersioned.sol/interface.IVersioned.md)

TCAP v2 is an index token that is pegged to the entire crypto market cap


## Functions
### mint

Mints new TCAP tokens

*Only callable by registered vaults*


```solidity
function mint(address to, uint256 amount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`to`|`address`|The address to mint the tokens to|
|`amount`|`uint256`|The amount of tokens to mint|


### burn

Burns TCAP tokens

*Only callable by registered vaults*


```solidity
function burn(address from, uint256 amount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`from`|`address`|The address to burn the tokens from|
|`amount`|`uint256`|The amount of tokens to burn|


### setOracle

Sets the new oracle for the crypto marketcap

*Only callable by the oracle setter*


```solidity
function setOracle(address newOracle) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newOracle`|`address`|The new oracle address|


### mintedAmount

Returns the amount of TCAP tokens minted by a vault


```solidity
function mintedAmount(address vault) external view returns (uint256);
```

### oracle


```solidity
function oracle() external view returns (address);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|The oracle of the crypto marketcap|


### latestPrice

*Defined as the value of the total crypto marketcap divided by the divisor*


```solidity
function latestPrice() external view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The target price of the TCAP token|


### latestPriceOf


```solidity
function latestPriceOf(uint256 amount) external view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The price of a given amount of TCAP tokens|


### DIVISOR


```solidity
function DIVISOR() external view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Value used as divisor with the total market cap, just like the S&P 500 or any major financial index would to define the final tcap token price|


## Events
### Minted
Emitted when a vault mints TCAP tokens


```solidity
event Minted(address indexed vault, address indexed recipient, uint256 amount);
```

### Burned
Emitted when a vault burns TCAP tokens


```solidity
event Burned(address indexed vault, address indexed recipient, uint256 amount);
```

### OracleUpdated
Emitted when the oracle is updated


```solidity
event OracleUpdated(address indexed newOracle);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newOracle`|`address`|The new oracle address|

## Errors
### BalanceExceeded
Thrown when a vault tries to burn more TCAP tokens than it has minted


```solidity
error BalanceExceeded(address vault);
```

