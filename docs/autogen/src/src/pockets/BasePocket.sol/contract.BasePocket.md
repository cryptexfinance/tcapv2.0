# BasePocket
[Git Source](https://github.com/cryptexfinance/tcapv2.0/blob/6bc13f590e0d259edfc7844b2201ce75ef760a67/src/pockets/BasePocket.sol)

**Inherits:**
[IPocket](/src/interface/pockets/IPocket.sol/interface.IPocket.md), Initializable

The base pocket stores all funds in this contract

*assumes the underlying token is the same as the overlying token.*


## State Variables
### BasePocketStorageLocation

```solidity
bytes32 private constant BasePocketStorageLocation = 0x5845aa409e8f916812e6478a8497f697ddaade604e35f24d88be5edf4ba35300;
```


### VAULT

```solidity
IVault public immutable VAULT;
```


### UNDERLYING_TOKEN

```solidity
IERC20 public immutable UNDERLYING_TOKEN;
```


### OVERLYING_TOKEN

```solidity
IERC20 public immutable OVERLYING_TOKEN;
```


## Functions
### constructor


```solidity
constructor(address vault_, address underlyingToken_, address overlyingToken_);
```

### initialize


```solidity
function initialize() public initializer;
```

### _getBasePocketStorage


```solidity
function _getBasePocketStorage() private pure returns (BasePocketStorage storage $);
```

### onlyVault


```solidity
modifier onlyVault();
```

### registerDeposit

called by the vault to deposit underlying tokens into the pocket

*requires `amountUnderlying` amount of underlying tokens to be deposited into the contract before calling this function*


```solidity
function registerDeposit(address user, uint256 amountUnderlying) external onlyVault returns (uint256 shares);
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


```solidity
function withdraw(address user, uint256 amountUnderlying, address recipient) external onlyVault returns (uint256 shares);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user`|`address`|The address of the user who withdraws the underlying tokens|
|`amountUnderlying`|`uint256`||
|`recipient`|`address`|The address of the recipient who receives the underlying tokens|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`shares`|`uint256`|amountUnderlying The amount of underlying tokens withdrawn|


### totalShares


```solidity
function totalShares() public view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|totalShares The total amount of shares issued by the pocket|


### sharesOf


```solidity
function sharesOf(address user) public view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|shares The amount of shares owned by the user|


### balanceOf


```solidity
function balanceOf(address user) public view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|amount The underlying balance of the user|


### totalBalance


```solidity
function totalBalance() public view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|amount The underlying balance of the contract|


### _onDeposit


```solidity
function _onDeposit(uint256 amountUnderlying) internal virtual returns (uint256 amountOverlying);
```

### _onWithdraw


```solidity
function _onWithdraw(uint256 amountOverlying, address recipient) internal virtual returns (uint256 amountUnderlying);
```

### _balanceOf


```solidity
function _balanceOf(address user) internal view virtual returns (uint256);
```

### _totalBalance


```solidity
function _totalBalance() internal view virtual returns (uint256);
```

### version


```solidity
function version() external pure virtual override returns (string memory);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`string`|The version of the contract|


## Structs
### BasePocketStorage

```solidity
struct BasePocketStorage {
    uint256 totalShares;
    mapping(address user => uint256 shares) sharesOf;
}
```

