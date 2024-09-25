# Vault
[Git Source](https://github.com/cryptexfinance/tcapv2.0/blob/c8b18bb160f52905d87ef82a6a1c3fee16403c7f/src/Vault.sol)

**Inherits:**
[IVault](/src/interface/IVault.sol/interface.IVault.md), AccessControl, [Multicall](/src/lib/Multicall.sol/abstract.Multicall.md)

Vaults manage deposits of collateral and mint TCAP tokens


## State Variables
### VaultStorageLocation

```solidity
bytes32 private constant VaultStorageLocation = 0xead32f79207e43129359e4c6890b619e37e73a4cc1d61050c081a5aea1b4df00;
```


### TCAPV2

```solidity
ITCAPV2 public immutable TCAPV2;
```


### COLLATERAL

```solidity
IERC20 public immutable COLLATERAL;
```


### PERMIT2

```solidity
IPermit2 private immutable PERMIT2;
```


### COLLATERAL_DECIMALS

```solidity
uint8 private immutable COLLATERAL_DECIMALS;
```


## Functions
### ensureLoanHealthy

*ensures loan is healthy after any action is performed*


```solidity
modifier ensureLoanHealthy(address user, uint96 pocketId);
```

### constructor


```solidity
constructor(ITCAPV2 tCAPV2_, IERC20 collateral_, IPermit2 permit2_);
```

### initialize


```solidity
function initialize(address admin, uint16 initialFee, address oracle_, address feeRecipient_, IVault.LiquidationParams calldata liquidationParams_)
    public
    initializer;
```

### _getVaultStorage


```solidity
function _getVaultStorage() private pure returns (VaultStorage storage $);
```

### addPocket

Adds a new pocket to the vault

*Only callable by the admin*


```solidity
function addPocket(IPocket pocket) external onlyRole(Roles.POCKET_SETTER_ROLE) returns (uint96 pocketId);
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
function disablePocket(uint96 pocketId) external onlyRole(Roles.POCKET_SETTER_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`pocketId`|`uint96`|The id of the pocket to disable|


### updateInterestRate

Updates the interest rate of the vault

*Only callable by the fee setter*


```solidity
function updateInterestRate(uint16 fee) external onlyRole(Roles.FEE_SETTER_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`fee`|`uint16`|The new interest rate|


### updateFeeRecipient

Updates the fee recipient of the vault

*Only callable by the fee setter*


```solidity
function updateFeeRecipient(address newFeeRecipient) external onlyRole(Roles.FEE_SETTER_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newFeeRecipient`|`address`|The new fee recipient address|


### updateOracle

Updates the oracle of the collateral

*Only callable by the oracle setter*


```solidity
function updateOracle(address newOracle) external onlyRole(Roles.ORACLE_SETTER_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newOracle`|`address`|The new oracle address|


### updateLiquidationParams

Updates the liquidation params of the vault

*Only callable by the admin*


```solidity
function updateLiquidationParams(LiquidationParams calldata newParams) external onlyRole(Roles.LIQUIDATION_SETTER_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newParams`|`LiquidationParams`||


### deposit

Deposits collateral into a pocket


```solidity
function deposit(uint96 pocketId, uint256 amount) external returns (uint256 shares);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`pocketId`|`uint96`|The id of the pocket to deposit to|
|`amount`|`uint256`||

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`shares`|`uint256`|The amount of shares minted by the pocket|


### depositWithPermit

Deposits collateral into a pocket using a permit2 signature transfer


```solidity
function depositWithPermit(uint96 pocketId, uint256 amount, IPermit2.PermitTransferFrom calldata permit, bytes calldata signature)
    external
    returns (uint256 shares);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`pocketId`|`uint96`|The id of the pocket to deposit to|
|`amount`|`uint256`||
|`permit`|`IPermit2.PermitTransferFrom`|The permit data|
|`signature`|`bytes`|The signature|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`shares`|`uint256`|The amount of shares minted by the pocket|


### withdraw

Withdraws collateral from a pocket

*Takes the accrued fees from the user*


```solidity
function withdraw(uint96 pocketId, uint256 amount, address to) external ensureLoanHealthy(msg.sender, pocketId) returns (uint256 shares);
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
function mint(uint96 pocketId, uint256 amount) external ensureLoanHealthy(msg.sender, pocketId);
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


### takeFee

Takes the accrued fees from a user and sends them to the fee recipient


```solidity
function takeFee(address user, uint96 pocketId) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user`|`address`|The address of the user to take the fees from|
|`pocketId`|`uint96`|The id of the pocket where the collateral is stored|


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


### healthFactor

Returns the health factor of a user


```solidity
function healthFactor(address user, uint96 pocketId) public view returns (uint256);
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
function collateralValueOf(uint256 amount) public view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of collateral|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The value of the collateral|


### mintedValueOf

Returns the value of `amount` of TCAP tokens


```solidity
function mintedValueOf(uint256 amount) public view returns (uint256);
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
function collateralOf(address user, uint96 pocketId) public view returns (uint256);
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
function mintedAmountOf(address user, uint96 pocketId) public view returns (uint256);
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
function outstandingInterestOf(address user, uint96 pocketId) public view returns (uint256);
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
function latestPrice() public view returns (uint256);
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
function liquidationParams() public view returns (IVault.LiquidationParams memory params);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`params`|`IVault.LiquidationParams`|The liquidation params of the vault|


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


### _takeFee


```solidity
function _takeFee(IPocket pocket, address user, uint96 pocketId) internal;
```

### _updateInterestRate


```solidity
function _updateInterestRate(uint16 fee) internal;
```

### _updateFeeRecipient


```solidity
function _updateFeeRecipient(address newFeeRecipient) internal;
```

### _updateLiquidationParams


```solidity
function _updateLiquidationParams(IVault.LiquidationParams calldata liquidation) internal;
```

### _updateOracle


```solidity
function _updateOracle(address newOracle) internal;
```

### _getPocket


```solidity
function _getPocket(uint96 pocketId) internal view returns (IPocket);
```

### _balanceOf


```solidity
function _balanceOf(address user, uint96 pocketId) internal view returns (uint256);
```

### _toMintId


```solidity
function _toMintId(address user, uint96 pocketId) internal pure returns (uint256);
```

### version


```solidity
function version() external pure returns (string memory);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`string`|The version of the contract|


## Structs
### Deposit

```solidity
struct Deposit {
    uint256 mintAmount;
    uint256 feeIndex;
    uint256 accruedInterest;
}
```

### Pocket

```solidity
struct Pocket {
    IPocket pocket;
    bool enabled;
}
```

### FeeData

```solidity
struct FeeData {
    uint256 index;
    uint16 fee;
    uint40 lastUpdated;
}
```

### MintData

```solidity
struct MintData {
    mapping(uint256 mintId => Deposit deposit) deposits;
    FeeData feeData;
}
```

### VaultStorage

```solidity
struct VaultStorage {
    mapping(uint96 pocketId => Pocket pocket) pockets;
    uint96 pocketCounter;
    IOracle oracle;
    address feeRecipient;
    IVault.LiquidationParams liquidationParams;
    MintData mintData;
}
```

