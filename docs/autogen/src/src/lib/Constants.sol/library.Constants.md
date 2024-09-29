# Constants
[Git Source](https://github.com/cryptexfinance/tcapv2.0/blob/50c7925a6c3f309de1ec1ac1c16e55792a14efef/src/lib/Constants.sol)


## State Variables
### MIN_LIQUIDATION_THRESHOLD

```solidity
uint64 internal constant MIN_LIQUIDATION_THRESHOLD = 1e18;
```


### MAX_LIQUIDATION_THRESHOLD

```solidity
uint64 internal constant MAX_LIQUIDATION_THRESHOLD = 3e18;
```


### MAX_LIQUIDATION_PENALTY

```solidity
uint64 internal constant MAX_LIQUIDATION_PENALTY = 0.5e18;
```


### MIN_POST_LIQUIDATION_HEALTH_FACTOR

```solidity
uint64 internal constant MIN_POST_LIQUIDATION_HEALTH_FACTOR = 1;
```


### MAX_POST_LIQUIDATION_HEALTH_FACTOR

```solidity
uint64 internal constant MAX_POST_LIQUIDATION_HEALTH_FACTOR = 1e18;
```


### MAX_FEE

```solidity
uint256 internal constant MAX_FEE = 10_000;
```


### TCAP_DECIMALS

```solidity
uint8 internal constant TCAP_DECIMALS = 18;
```


### DIVISOR

```solidity
uint256 internal constant DIVISOR = 1e10;
```


### DECIMAL_OFFSET
*multiply pocket shares with a decimal offset to mitigate inflation attack*


```solidity
uint256 internal constant DECIMAL_OFFSET = 1e6;
```


