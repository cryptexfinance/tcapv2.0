# FeeCalculatorLib
[Git Source](https://github.com/cryptexfinance/tcapv2.0/blob/34a621b9d7f953a62f8f826356dda361dde059e4/src/lib/FeeCalculatorLib.sol)


## State Variables
### MAX_FEE

```solidity
uint256 internal constant MAX_FEE = 10_000;
```


## Functions
### modifyPosition


```solidity
function modifyPosition(Vault.MintData storage $, uint256 mintId, int256 amount) internal;
```

### feeIndex


```solidity
function feeIndex(Vault.MintData storage $) internal view returns (uint256);
```

### updateFeeIndex


```solidity
function updateFeeIndex(Vault.MintData storage $) internal returns (uint256 index);
```

### setInterestRate


```solidity
function setInterestRate(Vault.MintData storage $, uint16 fee) internal;
```

### interestOf


```solidity
function interestOf(Vault.MintData storage $, uint256 mintId) internal view returns (uint256 interest);
```

### resetInterestOf


```solidity
function resetInterestOf(Vault.MintData storage $, uint256 mintId) internal;
```

### outstandingInterest


```solidity
function outstandingInterest(Vault.MintData storage $, uint256 index, uint256 mintId) private view returns (uint256 interest);
```

### MULTIPLIER

*ensures correct calculation for small amounts*


```solidity
function MULTIPLIER() private pure returns (uint256);
```

