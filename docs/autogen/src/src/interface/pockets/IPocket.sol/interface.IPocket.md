# IPocket
[Git Source](https://github.com/cryptexfinance/tcapv2.0/blob/2f8879d8504dc4ec7a920d1fe0743d765f4412f1/src/interface/pockets/IPocket.sol)

**Inherits:**
[IVersioned](/src/interface/IVersioned.sol/interface.IVersioned.md)

Base interface for all pockets

A pocket is used to separate deposited funds based on their use case


## Functions
### registerDeposit

called by the vault to deposit underlying tokens into the pocket

*requires `amountUnderlying` amount of underlying tokens to be deposited into the contract before calling this function*

*Only callable by the vault*


```solidity
function registerDeposit(address user, uint256 amountUnderlying) external returns (uint256 shares);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user`|`address`|The address of the user who deposits the underlying tokens|
|`amountUnderlying`|`uint256`|The amount of underlying tokens deposited|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`shares`|`uint256`|The amount of shares received|


### withdraw

called by the vault to withdraw underlying tokens from the pocket

*Only callable by the vault*

*MUST revert if more shares are withdrawn than shares owned by user*


```solidity
function withdraw(address user, uint256 shares, address recipient) external returns (uint256 amountUnderlying);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user`|`address`|The address of the user who withdraws the underlying tokens|
|`shares`|`uint256`|The amount of shares burned|
|`recipient`|`address`|The address of the recipient who receives the underlying tokens|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`amountUnderlying`|`uint256`|The amount of underlying tokens withdrawn|


### VAULT


```solidity
function VAULT() external view returns (IVault);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`IVault`|vault The vault that the pocket is registered to|


### UNDERLYING_TOKEN


```solidity
function UNDERLYING_TOKEN() external view returns (IERC20);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`IERC20`|underlyingToken The underlying token of the pocket, e.g. WETH|


### OVERLYING_TOKEN

*the overlying token can be an Aave aToken (e.g., aWETH), it can also be equal to the underlying token*


```solidity
function OVERLYING_TOKEN() external view returns (IERC20);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`IERC20`|overlyingToken The overlying token of the pocket|


### totalShares


```solidity
function totalShares() external view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|totalShares The total amount of shares issued by the pocket|


### sharesOf


```solidity
function sharesOf(address user) external view returns (uint256 shares);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`shares`|`uint256`|The amount of shares owned by the user|


### totalBalance


```solidity
function totalBalance() external view returns (uint256 amount);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The underlying balance of the contract|


### balanceOf


```solidity
function balanceOf(address user) external view returns (uint256 amount);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The underlying balance of the user|


## Events
### Deposit
Emitted when a user deposits underlying tokens into the pocket


```solidity
event Deposit(address indexed user, uint256 amountUnderlying, uint256 amountOverlying, uint256 shares);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user`|`address`|The address of the user who deposited the underlying tokens|
|`amountUnderlying`|`uint256`|The amount of underlying tokens deposited|
|`amountOverlying`|`uint256`|The amount of overlying tokens added to the users balance|
|`shares`|`uint256`|The amount of shares received|

### Withdrawal
Emitted when a user withdraws underlying tokens from the pocket


```solidity
event Withdrawal(address indexed user, address indexed recipient, uint256 amountUnderlying, uint256 amountOverlying, uint256 shares);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user`|`address`|The address of the user who withdrew the underlying tokens|
|`recipient`|`address`|The address of the recipient who received the underlying tokens|
|`amountUnderlying`|`uint256`|The amount of underlying tokens withdrawn|
|`amountOverlying`|`uint256`|The amount of overlying tokens removed from the users balance|
|`shares`|`uint256`|The amount of shares burned|

## Errors
### Unauthorized
Emitted when an account that is not the vault calls a restricted function


```solidity
error Unauthorized();
```

### InsufficientFunds
Thrown when a user tries to burn more shares than they own


```solidity
error InsufficientFunds();
```

