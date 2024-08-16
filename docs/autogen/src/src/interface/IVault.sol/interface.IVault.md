# IVault
[Git Source](https://github.com/cryptexfinance/tcapv2.0/blob/34a621b9d7f953a62f8f826356dda361dde059e4/src/interface/IVault.sol)

**Inherits:**
IAccessControl, [IMulticall](/src/interface/IMulticall.sol/interface.IMulticall.md), [IVersioned](/src/interface/IVersioned.sol/interface.IVersioned.md)

Vaults manage deposits of collateral and mint TCAP tokens


## Functions
### addPocket

Adds a new pocket to the vault

*Only callable by the admin*


```solidity
function addPocket(IPocket pocket) external returns (uint88 pocketId);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`pocket`|`IPocket`|The pocket to add|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`pocketId`|`uint88`|The generated id of the pocket|


### disablePocket

Disables a pocket to be used for deposits

*Only callable by the admin*


```solidity
function disablePocket(uint88 pocketId) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`pocketId`|`uint88`|The id of the pocket to disable|


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


### updateLiquidationThreshold

Updates the liquidation threshold of the vault

*Only callable by the admin*


```solidity
function updateLiquidationThreshold(uint96 newLiquidationThreshold) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newLiquidationThreshold`|`uint96`|The new liquidation threshold|


### deposit

Deposits collateral into a pocket


```solidity
function deposit(uint88 pocketId, uint256 collateralAmount) external returns (uint256 shares);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`pocketId`|`uint88`|The id of the pocket to deposit to|
|`collateralAmount`|`uint256`|The amount of collateral to deposit|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`shares`|`uint256`|The amount of shares minted by the pocket|


### depositWithPermit

Deposits collateral into a pocket using a permit2 signature transfer


```solidity
function depositWithPermit(uint88 pocketId, uint256 collateralAmount, IPermit2.PermitTransferFrom memory permit, bytes calldata signature)
    external
    returns (uint256 shares);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`pocketId`|`uint88`|The id of the pocket to deposit to|
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
function withdraw(uint88 pocketId, uint256 amount, address to) external returns (uint256 shares);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`pocketId`|`uint88`|The id of the pocket to withdraw from|
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
function mint(uint88 pocketId, uint256 amount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`pocketId`|`uint88`|The id of the pocket where the collateral is stored|
|`amount`|`uint256`|The amount of TCAP tokens to mint|


### burn

Burns TCAP tokens


```solidity
function burn(uint88 pocketId, uint256 amount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`pocketId`|`uint88`|The id of the pocket where the collateral is stored|
|`amount`|`uint256`|The amount of TCAP tokens to burn|


### liquidate

Liquidates a user's loan

*Throws if the loan is not healthy*


```solidity
function liquidate(address user, uint88 pocketId) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user`|`address`|The address of the user to liquidate|
|`pocketId`|`uint88`|The id of the pocket where the collateral is stored|


### healthFactor

Returns the health factor of a user


```solidity
function healthFactor(address user, uint88 pocketId) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user`|`address`|The address of the user|
|`pocketId`|`uint88`|The id of the pocket|

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
function collateralValueOfUser(address user, uint88 pocketId) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user`|`address`|The address of the user|
|`pocketId`|`uint88`|The id of the pocket|

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
function mintedValueOfUser(address user, uint88 pocketId) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user`|`address`|The address of the user|
|`pocketId`|`uint88`|The id of the pocket|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The value of the TCAP tokens of the user|


### collateralOf

Returns the amount of collateral of a user


```solidity
function collateralOf(address user, uint88 pocketId) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user`|`address`|The address of the user|
|`pocketId`|`uint88`|The id of the pocket|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The amount of collateral of the user|


### mintedAmountOf

Returns the amount of TCAP tokens minted by a user


```solidity
function mintedAmountOf(address user, uint88 pocketId) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user`|`address`|The address of the user|
|`pocketId`|`uint88`|The id of the pocket|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The amount of TCAP tokens minted by the user|


### outstandingInterestOf

Returns the outstanding interest of a user denominated in the collateral


```solidity
function outstandingInterestOf(address user, uint88 pocketId) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user`|`address`|The address of the user|
|`pocketId`|`uint88`|The id of the pocket|

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


### liquidationThreshold


```solidity
function liquidationThreshold() external view returns (uint96);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint96`|The liquidation threshold of the vault|


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
function pockets(uint88 id) external view returns (IPocket);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`IPocket`|The pocket with the given id|


### pocketEnabled


```solidity
function pocketEnabled(uint88 id) external view returns (bool);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|Whether the pocket with the given id is enabled|


## Events
### PocketAdded
Emitted when a pocket is added


```solidity
event PocketAdded(uint88 pocketId, IPocket pocket);
```

### PocketDisabled
Emitted when a pocket is disabled


```solidity
event PocketDisabled(uint88 pocketId);
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

### LiquidationThresholdUpdated
Emitted when the liquidation threshold is updated


```solidity
event LiquidationThresholdUpdated(uint256 newLiquidationThreshold);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newLiquidationThreshold`|`uint256`|The new liquidation threshold|

### Deposited
Emitted when a deposit of collateral is made


```solidity
event Deposited(address indexed user, uint88 indexed pocketId, uint256 collateralAmount, uint256 shares);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user`|`address`|The address of the user who made the deposit|
|`pocketId`|`uint88`|The id of the pocket the deposit was made to|
|`collateralAmount`|`uint256`|The amount of collateral deposited|
|`shares`|`uint256`|The amount of shares minted by the pocket|

### Withdrawn
Emitted when a withdrawal of collateral is made


```solidity
event Withdrawn(address indexed user, uint88 indexed pocketId, address indexed recipient, uint256 amount, uint256 shares);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user`|`address`|The address of the user who made the withdrawal|
|`pocketId`|`uint88`|The id of the pocket the withdrawal was made from|
|`recipient`|`address`|The address of the recipient of the withdrawal|
|`amount`|`uint256`|The amount of collateral withdrawn|
|`shares`|`uint256`|The amount of shares burned|

### Minted
Emitted when TCAP tokens are minted


```solidity
event Minted(address indexed user, uint88 indexed pocketId, uint256 amount);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user`|`address`|The address of the user who minted the tokens|
|`pocketId`|`uint88`|The id of the pocket where the collateral is stored|
|`amount`|`uint256`|The amount of TCAP tokens minted|

### Burned
Emitted when TCAP tokens are burned


```solidity
event Burned(address indexed user, uint88 indexed pocketId, uint256 amount);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user`|`address`|The address of the user who burned the tokens|
|`pocketId`|`uint88`|The id of the pocket where the collateral is stored|
|`amount`|`uint256`|The amount of TCAP tokens burned|

### Liquidated
Emitted when a loan of TCAP tokens is liquidated


```solidity
event Liquidated(address indexed liquidator, address indexed user, uint88 indexed pocketId, uint256 collateralAmount, uint256 mintAmount);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`liquidator`|`address`|The address of the liquidator|
|`user`|`address`|The address of the user who was liquidated|
|`pocketId`|`uint88`|The id of the pocket where the collateral is stored|
|`collateralAmount`|`uint256`|The amount of collateral liquidated|
|`mintAmount`|`uint256`|The amount of TCAP tokens liquidated|

## Errors
### InvalidValue
Thrown when a user provides an invalid value


```solidity
error InvalidValue();
```

### PocketNotEnabled
Thrown when a user tries to deposit to a pocket that is not enabled


```solidity
error PocketNotEnabled(uint88 pocketId);
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

