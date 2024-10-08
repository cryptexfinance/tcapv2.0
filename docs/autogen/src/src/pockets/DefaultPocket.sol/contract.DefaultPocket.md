# DefaultPocket
[Git Source](https://github.com/cryptexfinance/tcapv2.0/blob/300e3dc5cffa328fb9714b67c38745c3400cb13b/src/pockets/DefaultPocket.sol)

**Inherits:**
[BasePocket](/src/pockets/BasePocket.sol/abstract.BasePocket.md)

The default pocket that simply stores the underlying token in this contract

*assumes the underlying token is the same as the overlying token.*


## Functions
### constructor


```solidity
constructor(address vault_, address underlyingToken_) BasePocket(vault_, underlyingToken_, underlyingToken_);
```

### initialize


```solidity
function initialize() public override initializer;
```

### _onDeposit


```solidity
function _onDeposit(uint256 amountUnderlying) internal pure override returns (uint256 amountOverlying);
```

### _onWithdraw


```solidity
function _onWithdraw(uint256 amountOverlying, address recipient) internal override returns (uint256 amountUnderlying);
```

### _balanceOf


```solidity
function _balanceOf(address user) internal view override returns (uint256);
```

### _totalBalance


```solidity
function _totalBalance() internal view override returns (uint256);
```

### version


```solidity
function version() external pure virtual override returns (string memory);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`string`|The version of the contract|


