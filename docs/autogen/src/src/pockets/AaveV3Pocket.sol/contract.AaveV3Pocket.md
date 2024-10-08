# AaveV3Pocket
[Git Source](https://github.com/cryptexfinance/tcapv2.0/blob/300e3dc5cffa328fb9714b67c38745c3400cb13b/src/pockets/AaveV3Pocket.sol)

**Inherits:**
[BasePocket](/src/pockets/BasePocket.sol/abstract.BasePocket.md), [IAaveV3Pocket](/src/interface/pockets/IAaveV3Pocket.sol/interface.IAaveV3Pocket.md)

The Aave v3 Pocket deposits funds into Aave v3 to earn interest


## State Variables
### POOL

```solidity
IPool public immutable POOL;
```


## Functions
### constructor


```solidity
constructor(address vault_, address underlyingToken_, address aavePool)
    BasePocket(vault_, underlyingToken_, IPool(aavePool).getReserveData(underlyingToken_).aTokenAddress);
```

### initialize


```solidity
function initialize() public override initializer;
```

### _onDeposit

*deposits underlying token into Aave v3, aTokens are deposited into this pocket*


```solidity
function _onDeposit(uint256 amountUnderlying) internal override returns (uint256 amountOverlying);
```

### _onWithdraw

*redeems aTokens with Aave v3, underlying token is returned to user*


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
function version() external pure override(BasePocket, IVersioned) returns (string memory);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`string`|The version of the contract|


