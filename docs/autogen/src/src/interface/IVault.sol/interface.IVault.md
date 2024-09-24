# IVault
[Git Source](https://github.com/cryptexfinance/tcapv2.0/blob/3fb7671f959cafc2399d81b93557d37c7898477b/src/interface/IVault.sol)

**Inherits:**
IAccessControl, [IMulticall](/src/interface/IMulticall.sol/interface.IMulticall.md), [IVersioned](/src/interface/IVersioned.sol/interface.IVersioned.md)

Vaults manage deposits of collateral and mint TCAP tokens


## Functions
### addPocket

Adds a new pocket to the vault

*Only callable by the admin*


```solidity
function addPocket(IPocket pocket) external returns (uint96 pocketId);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`pocket`|`IPocket`|The pocket to add|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`pocketId`|`uint96`|The generated id of the pocket|


### disablePocket

Disables a pocket to be used for deposits

*Only callable by the admin*


```solidity
function disablePocket(uint96 pocketId) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`pocketId`|`uint96`|The id of the pocket to disable|


### updateInterestRate

Updates the interest rate of the vault

*Only callable by the fee setter*


```solidity
function updateInterestRate(uint16 fee) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`fee`|`uint16`|The new interest rate|


### updateFeeRecipient

Updates the fee recipient of the vault

*Only callable by the fee setter*


```solidity
function updateFeeRecipient(address newFeeRecipient) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newFeeRecipient`|`address`|The new fee recipient address|


### updateOracle

Updates the oracle of the collateral

*Only callable by the oracle setter*


```solidity
function updateOracle(address newOracle) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newOracle`|`address`|The new oracle address|


### updateLiquidationParams

Updates the liquidation params of the vault

*Only callable by the admin*


```solidity
function updateLiquidationParams(LiquidationParams calldata newLiquidationParams) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newLiquidationParams`|`LiquidationParams`|The new liquidation params|


### deposit

Deposits collateral into a pocket


```solidity
function deposit(uint96 pocketId, uint256 collateralAmount) external returns (uint256 shares);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`pocketId`|`uint96`|The id of the pocket to deposit to|
|`collateralAmount`|`uint256`|The amount of collateral to deposit|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`shares`|`uint256`|The amount of shares minted by the pocket|


### depositWithPermit

Deposits collateral into a pocket using a permit2 signature transfer


```solidity
function depositWithPermit(uint96 pocketId, uint256 collateralAmount, IPermit2.PermitTransferFrom calldata permit, bytes calldata signature)
    external
    returns (uint256 shares);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`pocketId`|`uint96`|The id of the pocket to deposit to|
|`collateralAmount`|`uint256`|The amount of collateral to deposit|
|`permit`|`IPermit2.PermitTransferFrom`|The permit data|
|`signature`|`bytes`|The signature|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`shares`|`uint256`|The amount of shares minted by the pocket|


### withdraw

Withdraws collateral from a pocket

*Takes the accrued fees from the user*

*Throws if the loan is not healthy after withdrawing*


```solidity
function withdraw(uint96 pocketId, uint256 amount, address to) external returns (uint256 shares);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`pocketId`|`uint96`|The id of the pocket to withdraw from|
|`amount`|`uint256`|The amount of collateral to withdraw|
|`to`|`address`|The address to withdraw the collateral to|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`shares`|`uint256`|The amount of shares burned|


### mint

Mints TCAP tokens

*Throws if the loan is not healthy after minting*


```solidity
function mint(uint96 pocketId, uint256 amount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`pocketId`|`uint96`|The id of the pocket where the collateral is stored|
|`amount`|`uint256`|The amount of TCAP tokens to mint|


### burn

Burns TCAP tokens


```solidity
function burn(uint96 pocketId, uint256 amount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`pocketId`|`uint96`|The id of the pocket where the collateral is stored|
|`amount`|`uint256`|The amount of TCAP tokens to burn|


### liquidate

Liquidates a user's loan

*Throws if the loan is not healthy*

*after the liquidation the health factor must be between the minimum and maximum bounds of the liquidation params*


```solidity
function liquidate(address user, uint96 pocketId, uint256 burnAmount) external returns (uint256 liquidationReward);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user`|`address`|The address of the user to liquidate|
|`pocketId`|`uint96`|The id of the pocket where the collateral is stored|
|`burnAmount`|`uint256`|The amount of TCAP tokens to burn|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`liquidationReward`|`uint256`|The amount of collateral liquidated and returned to the liquidator|


### healthFactor

Returns the health factor of a user


```solidity
function healthFactor(address user, uint96 pocketId) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user`|`address`|The address of the user|
|`pocketId`|`uint96`|The id of the pocket|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The health factor of the user|


### collateralValueOf

Returns the value of `amount` of collateral tokens


```solidity
function collateralValueOf(uint256 amount) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of collateral|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The value of the collateral|


### collateralValueOfUser

Returns the value of the collateral of a user


```solidity
function collateralValueOfUser(address user, uint96 pocketId) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user`|`address`|The address of the user|
|`pocketId`|`uint96`|The id of the pocket|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The value of the collateral of the user|


### mintedValueOf

Returns the value of `amount` of TCAP tokens


```solidity
function mintedValueOf(uint256 amount) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of TCAP tokens|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The value of the TCAP tokens|


### mintedValueOfUser

Returns the value of minted TCAP tokens by a user


```solidity
function mintedValueOfUser(address user, uint96 pocketId) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user`|`address`|The address of the user|
|`pocketId`|`uint96`|The id of the pocket|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The value of the TCAP tokens of the user|


### collateralOf

Returns the amount of collateral of a user


```solidity
function collateralOf(address user, uint96 pocketId) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user`|`address`|The address of the user|
|`pocketId`|`uint96`|The id of the pocket|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The amount of collateral of the user|


### mintedAmountOf

Returns the amount of TCAP tokens minted by a user


```solidity
function mintedAmountOf(address user, uint96 pocketId) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user`|`address`|The address of the user|
|`pocketId`|`uint96`|The id of the pocket|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The amount of TCAP tokens minted by the user|


### outstandingInterestOf

Returns the outstanding interest of a user denominated in the collateral


```solidity
function outstandingInterestOf(address user, uint96 pocketId) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user`|`address`|The address of the user|
|`pocketId`|`uint96`|The id of the pocket|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The outstanding interest of the user|


### latestPrice


```solidity
function latestPrice() external view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The latest price of the collateral|


### oracle


```solidity
function oracle() external view returns (address);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|The oracle of the collateral|


### interestRate


```solidity
function interestRate() external view returns (uint16);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint16`|The current interest rate of the vault|


### feeRecipient


```solidity
function feeRecipient() external view returns (address);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|The fee recipient of the vault|


### liquidationParams


```solidity
function liquidationParams() external view returns (LiquidationParams memory);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`LiquidationParams`|The liquidation params of the vault|


### TCAPV2


```solidity
function TCAPV2() external view returns (ITCAPV2);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`ITCAPV2`|The TCAPV2 contract|


### COLLATERAL


```solidity
function COLLATERAL() external view returns (IERC20);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`IERC20`|The collateral token of the vault|


### pockets


```solidity
function pockets(uint96 id) external view returns (IPocket);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`IPocket`|The pocket with the given id|


### pocketEnabled


```solidity
function pocketEnabled(uint96 id) external view returns (bool);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|Whether the pocket with the given id is enabled|


## Events
### PocketAdded
Emitted when a pocket is added


```solidity
event PocketAdded(uint96 pocketId, IPocket pocket);
```

### PocketDisabled
Emitted when a pocket is disabled


```solidity
event PocketDisabled(uint96 pocketId);
```

### InterestRateUpdated
Emitted when the interest rate is updated


```solidity
event InterestRateUpdated(uint16 fee);
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

### FeeRecipientUpdated
Emitted when the fee recipient is updated


```solidity
event FeeRecipientUpdated(address indexed newFeeRecipient);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newFeeRecipient`|`address`|The new fee recipient address|

### LiquidationParamsUpdated
Emitted when the liquidation params are updated


```solidity
event LiquidationParamsUpdated(LiquidationParams newLiquidationParams);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newLiquidationParams`|`LiquidationParams`|The new liquidation params|

### Deposited
Emitted when a deposit of collateral is made


```solidity
event Deposited(address indexed user, uint96 indexed pocketId, uint256 collateralAmount, uint256 shares);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user`|`address`|The address of the user who made the deposit|
|`pocketId`|`uint96`|The id of the pocket the deposit was made to|
|`collateralAmount`|`uint256`|The amount of collateral deposited|
|`shares`|`uint256`|The amount of shares minted by the pocket|

### Withdrawn
Emitted when a withdrawal of collateral is made


```solidity
event Withdrawn(address indexed user, uint96 indexed pocketId, address indexed recipient, uint256 amount, uint256 shares);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user`|`address`|The address of the user who made the withdrawal|
|`pocketId`|`uint96`|The id of the pocket the withdrawal was made from|
|`recipient`|`address`|The address of the recipient of the withdrawal|
|`amount`|`uint256`|The amount of collateral withdrawn|
|`shares`|`uint256`|The amount of shares burned|

### Minted
Emitted when TCAP tokens are minted


```solidity
event Minted(address indexed user, uint96 indexed pocketId, uint256 amount);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user`|`address`|The address of the user who minted the tokens|
|`pocketId`|`uint96`|The id of the pocket where the collateral is stored|
|`amount`|`uint256`|The amount of TCAP tokens minted|

### Burned
Emitted when TCAP tokens are burned


```solidity
event Burned(address indexed user, uint96 indexed pocketId, uint256 amount);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user`|`address`|The address of the user who burned the tokens|
|`pocketId`|`uint96`|The id of the pocket where the collateral is stored|
|`amount`|`uint256`|The amount of TCAP tokens burned|

### Liquidated
Emitted when a loan of TCAP tokens is liquidated


```solidity
event Liquidated(address indexed liquidator, address indexed user, uint96 indexed pocketId, uint256 collateralAmount, uint256 mintAmount);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`liquidator`|`address`|The address of the liquidator|
|`user`|`address`|The address of the user who was liquidated|
|`pocketId`|`uint96`|The id of the pocket where the collateral is stored|
|`collateralAmount`|`uint256`|The amount of collateral liquidated|
|`mintAmount`|`uint256`|The amount of TCAP tokens liquidated|

## Errors
### InvalidValue
Thrown when a user provides an invalid value


```solidity
error InvalidValue(ErrorCode code);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`code`|`ErrorCode`|The identifier of the error|

### PocketNotEnabled
Thrown when a user tries to deposit to a pocket that is not enabled


```solidity
error PocketNotEnabled(uint96 pocketId);
```

### InvalidToken
Thrown when a user provides an invalid token with a permit signature


```solidity
error InvalidToken();
```

### InsufficientMintedAmount
Thrown when a user tries to burn more TCAP tokens than they have minted using this vault


```solidity
error InsufficientMintedAmount();
```

### LoanNotHealthy
Thrown when a user mints or withdraws and the loan falls below the liquidation threshold


```solidity
error LoanNotHealthy();
```

### LoanHealthy
Thrown when a user is liquidated but the loan is still healthy


```solidity
error LoanHealthy();
```

## Structs
### LiquidationParams
Liquidation params of the vault

*after liquidation the health factor must be liquidationThreshold + minHealthFactor < x < liquidationThreshold + maxHealthFactor*

*e.g., liquidationThreshold + 10% < x < liquidationThreshold + 30%*


```solidity
struct LiquidationParams {
    uint64 threshold;
    uint64 penalty;
    uint64 minHealthFactor;
    uint64 maxHealthFactor;
}
```

**Properties**

|Name|Type|Description|
|----|----|-----------|
|`threshold`|`uint64`|The liquidation threshold|
|`penalty`|`uint64`|The liquidation penalty|
|`minHealthFactor`|`uint64`|The minimum health factor after liquidation added to the liquidation threshold|
|`maxHealthFactor`|`uint64`|The maximum health factor after liquidation added to the liquidation threshold|

## Enums
### ErrorCode

```solidity
enum ErrorCode {
    ZERO_VALUE,
    INVALID_POCKET,
    INVALID_POCKET_COLLATERAL,
    MAX_FEE,
    MAX_LIQUIDATION_PENALTY,
    MAX_LIQUIDATION_THRESHOLD,
    MIN_LIQUIDATION_THRESHOLD,
    MAX_POST_LIQUIDATION_HEALTH_FACTOR,
    MIN_POST_LIQUIDATION_HEALTH_FACTOR,
    INCOMPATIBLE_MAX_POST_LIQUIDATION_HEALTH_FACTOR,
    INVALID_BURN_AMOUNT,
    MUST_LIQUIDATE_ENTIRE_POSITION,
    HEALTH_FACTOR_BELOW_MINIMUM,
    HEALTH_FACTOR_ABOVE_MAXIMUM
}
```

