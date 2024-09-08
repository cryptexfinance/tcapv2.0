# Aavev3Pocket
[Git Source](https://github.com/cryptexfinance/tcapv2.0/blob/2f8879d8504dc4ec7a920d1fe0743d765f4412f1/src/pockets/AAVEv3Pocket.sol)

**Inherits:**
[BasePocket](/src/pockets/BasePocket.sol/contract.BasePocket.md), [IAavev3Pocket](/src/interface/pockets/IAAVEv3Pocket.sol/interface.IAavev3Pocket.md)

The Aave v3 Pocket deposits funds into Aave v3 to earn interest


## State Variables
### POOL

```solidity
IPool public immutable POOL;
```


## Functions
### constructor


```solidity
constructor(address vault_, address underlyingToken_, address overlyingToken_, address aavePool) BasePocket(vault_, underlyingToken_, overlyingToken_);
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


