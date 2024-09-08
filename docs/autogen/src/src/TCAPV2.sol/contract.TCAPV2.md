# TCAPV2
[Git Source](https://github.com/cryptexfinance/tcapv2.0/blob/6bc13f590e0d259edfc7844b2201ce75ef760a67/src/TCAPV2.sol)

**Inherits:**
[ITCAPV2](/src/interface/ITCAPV2.sol/interface.ITCAPV2.md), ERC20, AccessControl

TCAP v2 is an index token that is pegged to the entire crypto market cap


## State Variables
### TCAPV2StorageLocation

```solidity
bytes32 private constant TCAPV2StorageLocation = 0x49c710835f557391deaa6abce7163dc90464df5e070a25601335cdac43861e00;
```


### VAULT_ROLE

```solidity
bytes32 public constant VAULT_ROLE = keccak256("VAULT_ROLE");
```


### ORACLE_SETTER_ROLE

```solidity
bytes32 public constant ORACLE_SETTER_ROLE = keccak256("ORACLE_SETTER_ROLE");
```


### DIVISOR

```solidity
uint256 public constant DIVISOR = 1e10;
```


## Functions
### _getTCAPV2Storage


```solidity
function _getTCAPV2Storage() private pure returns (TCAPV2Storage storage $);
```

### constructor


```solidity
constructor();
```

### initialize

*oracle needs to be set after deployment*


```solidity
function initialize(address admin) external initializer;
```

### setOracle

Sets the new oracle for the crypto marketcap

*Only callable by the oracle setter*


```solidity
function setOracle(address newOracle) external onlyRole(ORACLE_SETTER_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newOracle`|`address`|The new oracle address|


### mint

Mints new TCAP tokens

*Only callable by registered vaults*


```solidity
function mint(address to, uint256 amount) external onlyRole(VAULT_ROLE);
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
function burn(address from, uint256 amount) external onlyRole(VAULT_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`from`|`address`|The address to burn the tokens from|
|`amount`|`uint256`|The amount of tokens to burn|


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
function latestPrice() public view returns (uint256);
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


### _setOracle


```solidity
function _setOracle(address newOracle) internal;
```

### version


```solidity
function version() external pure returns (string memory);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`string`|The version of the contract|


## Structs
### TCAPV2Storage

```solidity
struct TCAPV2Storage {
    mapping(address vault => uint256 amount) _mintedAmounts;
    IOracle oracle;
}
```

