# FeeCalculatorLib
[Git Source](https://github.com/cryptexfinance/tcapv2.0/blob/6bc13f590e0d259edfc7844b2201ce75ef760a67/src/lib/FeeCalculatorLib.sol)


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

