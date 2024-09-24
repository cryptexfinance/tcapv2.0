// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {AccessControlUpgradeable as AccessControl} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {Multicall} from "./lib/Multicall.sol";
import {ITCAPV2, IERC20} from "./interface/ITCAPV2.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IVault, IVersioned} from "./interface/IVault.sol";
import {IPocket} from "./interface/pockets/IPocket.sol";
import {FeeCalculatorLib} from "./lib/FeeCalculatorLib.sol";
import {IPermit2, ISignatureTransfer} from "permit2/src/interfaces/IPermit2.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {SafeTransferLib} from "solady/src/utils/SafeTransferLib.sol";
import {IOracle} from "./interface/IOracle.sol";
import {Constants, Roles} from "./lib/Constants.sol";
import {LiquidationLib} from "./lib/LiquidationLib.sol";

/// @title Vault
/// @notice Vaults manage deposits of collateral and mint TCAP tokens
contract Vault is IVault, AccessControl, Multicall {
    using FeeCalculatorLib for MintData;
    using SafeCast for uint256;
    using SafeTransferLib for address;

    struct Deposit {
        address user;
        uint96 pocketId;
        uint256 mintAmount;
        uint256 feeIndex;
        uint256 accruedInterest;
    }

    struct Pocket {
        IPocket pocket;
        bool enabled;
    }

    struct FeeData {
        uint256 index;
        uint16 fee;
        uint40 lastUpdated;
    }

    struct MintData {
        mapping(uint256 mintId => Deposit deposit) deposits;
        FeeData feeData;
    }

    /// @custom:storage-location erc7201:tcapv2.storage.vault
    struct VaultStorage {
        mapping(uint96 pocketId => Pocket pocket) pockets;
        uint96 pocketCounter;
        IOracle oracle;
        address feeRecipient;
        IVault.LiquidationParams liquidationParams;
        MintData mintData;
    }

    // keccak256(abi.encode(uint256(keccak256("tcapv2.storage.vault")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant VaultStorageLocation = 0xead32f79207e43129359e4c6890b619e37e73a4cc1d61050c081a5aea1b4df00;

    ITCAPV2 public immutable TCAPV2;
    IERC20 public immutable COLLATERAL;
    IPermit2 private immutable PERMIT2;
    uint8 private immutable COLLATERAL_DECIMALS;

    /// @dev ensures loan is healthy after any action is performed
    modifier ensureLoanHealthy(address user, uint96 pocketId) {
        _;
        if (healthFactor(user, pocketId) < liquidationParams().threshold) revert LoanNotHealthy();
    }

    constructor(ITCAPV2 tCAPV2_, IERC20 collateral_, IPermit2 permit2_) {
        TCAPV2 = tCAPV2_;
        COLLATERAL = collateral_;
        PERMIT2 = permit2_;
        COLLATERAL_DECIMALS = IERC20Metadata(address(collateral_)).decimals();
        _disableInitializers();
    }

    function initialize(address admin, uint16 initialFee, address oracle_, address feeRecipient_, IVault.LiquidationParams calldata liquidationParams_)
        public
        initializer
    {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _updateInterestRate(initialFee);
        _updateOracle(oracle_);
        _updateFeeRecipient(feeRecipient_);
        _updateLiquidationParams(liquidationParams_);
    }

    function _getVaultStorage() private pure returns (VaultStorage storage $) {
        assembly {
            $.slot := VaultStorageLocation
        }
    }

    /// @inheritdoc IVault
    function addPocket(IPocket pocket) external onlyRole(Roles.POCKET_SETTER_ROLE) returns (uint96 pocketId) {
        if (address(pocket) == address(0)) revert InvalidValue(IVault.ErrorCode.ZERO_VALUE);
        if (address(pocket.VAULT()) != address(this)) revert InvalidValue(IVault.ErrorCode.INVALID_POCKET);
        if (pocket.UNDERLYING_TOKEN() != COLLATERAL) revert InvalidValue(IVault.ErrorCode.INVALID_POCKET_COLLATERAL);
        VaultStorage storage $ = _getVaultStorage();
        pocketId = ++$.pocketCounter;
        $.pockets[pocketId] = Pocket({pocket: pocket, enabled: true});
        emit PocketAdded(pocketId, pocket);
    }

    /// @inheritdoc IVault
    function disablePocket(uint96 pocketId) external onlyRole(Roles.POCKET_SETTER_ROLE) {
        VaultStorage storage $ = _getVaultStorage();
        if (!$.pockets[pocketId].enabled) revert PocketNotEnabled(pocketId);
        $.pockets[pocketId].enabled = false;
        emit PocketDisabled(pocketId);
    }

    /// @inheritdoc IVault
    function updateInterestRate(uint16 fee) external onlyRole(Roles.FEE_SETTER_ROLE) {
        _updateInterestRate(fee);
    }

    /// @inheritdoc IVault
    function updateFeeRecipient(address newFeeRecipient) external onlyRole(Roles.FEE_SETTER_ROLE) {
        _updateFeeRecipient(newFeeRecipient);
    }

    /// @inheritdoc IVault
    function updateOracle(address newOracle) external onlyRole(Roles.ORACLE_SETTER_ROLE) {
        _updateOracle(newOracle);
    }

    /// @inheritdoc IVault
    function updateLiquidationParams(LiquidationParams calldata newParams) external onlyRole(Roles.LIQUIDATION_SETTER_ROLE) {
        _updateLiquidationParams(newParams);
    }

    /// @inheritdoc IVault
    function deposit(uint96 pocketId, uint256 amount) external returns (uint256 shares) {
        IPocket pocket = _getPocket(pocketId);
        address(COLLATERAL).safeTransferFrom(msg.sender, address(pocket), amount);
        shares = pocket.registerDeposit(msg.sender, amount);
        emit Deposited(msg.sender, pocketId, amount, shares);
    }

    /// @inheritdoc IVault
    function depositWithPermit(uint96 pocketId, uint256 amount, IPermit2.PermitTransferFrom calldata permit, bytes calldata signature)
        external
        returns (uint256 shares)
    {
        if (permit.permitted.token != address(COLLATERAL)) revert InvalidToken();
        IPocket pocket = _getPocket(pocketId);
        IPermit2.SignatureTransferDetails memory transferDetails = ISignatureTransfer.SignatureTransferDetails({to: address(pocket), requestedAmount: amount});
        PERMIT2.permitTransferFrom(permit, transferDetails, msg.sender, signature);
        shares = pocket.registerDeposit(msg.sender, amount);
        emit Deposited(msg.sender, pocketId, amount, shares);
    }

    /// @inheritdoc IVault
    function withdraw(uint96 pocketId, uint256 amount, address to) external ensureLoanHealthy(msg.sender, pocketId) returns (uint256 shares) {
        // @audit should be able to withdraw even if pocket is disabled
        IPocket pocket = _getVaultStorage().pockets[pocketId].pocket;
        _takeFee(pocket, msg.sender, pocketId);
        shares = pocket.withdraw(msg.sender, amount, to);
        emit Withdrawn(msg.sender, pocketId, to, amount, shares);
    }

    /// @inheritdoc IVault
    function mint(uint96 pocketId, uint256 amount) external ensureLoanHealthy(msg.sender, pocketId) {
        MintData storage $ = _getVaultStorage().mintData;
        $.modifyPosition(_toMintId(msg.sender, pocketId), amount.toInt256());
        TCAPV2.mint(msg.sender, amount);
        emit Minted(msg.sender, pocketId, amount);
    }

    /// @inheritdoc IVault
    function burn(uint96 pocketId, uint256 amount) external {
        MintData storage $ = _getVaultStorage().mintData;
        uint256 mintId = _toMintId(msg.sender, pocketId);
        if ($.deposits[mintId].mintAmount < amount) revert InsufficientMintedAmount();
        $.modifyPosition(mintId, -amount.toInt256());
        TCAPV2.burn(msg.sender, amount);
        emit Burned(msg.sender, pocketId, amount);
    }

    /// @inheritdoc IVault
    function liquidate(address user, uint96 pocketId, uint256 burnAmount) external returns (uint256 liquidationReward) {
        IPocket pocket = _getVaultStorage().pockets[pocketId].pocket;
        // @audit should be able to liquidate even if pocket is disabled
        _takeFee(pocket, user, pocketId);
        uint256 mintAmount = mintedAmountOf(user, pocketId);
        if (burnAmount > mintAmount) revert InvalidValue(IVault.ErrorCode.INVALID_BURN_AMOUNT);
        uint256 tcapPrice = TCAPV2.latestPrice();
        uint256 collateralAmount = collateralOf(user, pocketId);
        uint256 collateralPrice = latestPrice();
        IVault.LiquidationParams memory liquidation = liquidationParams();
        uint256 healthFactor_ = LiquidationLib.healthFactor(mintAmount, tcapPrice, collateralAmount, collateralPrice, COLLATERAL_DECIMALS);
        if (healthFactor_ >= liquidation.threshold) revert LoanHealthy();

        liquidationReward = LiquidationLib.liquidationReward(burnAmount, tcapPrice, collateralPrice, liquidation.penalty, COLLATERAL_DECIMALS);
        if (liquidationReward > collateralAmount) {
            // if mintValue < collateralValue + liquidationPenalty, liquidationReward will be > collateralAmount
            // in this case, we will liquidate the entire collateral
            // liquidation reward cannot be greater than collateral amount if the loan health is greater than 100% + liquidation penalty
            if (burnAmount != mintAmount) revert InvalidValue(IVault.ErrorCode.MUST_LIQUIDATE_ENTIRE_POSITION);
            liquidationReward = collateralAmount;
        } else {
            uint256 minBurnAmount = LiquidationLib.tokensRequiredForTargetHealthFactor(
                healthFactor_, liquidation.threshold + liquidation.minHealthFactor, mintAmount, liquidation.penalty
            );

            // if the minimum burn amount required to reach the minimum health factor is greater than the minted amount, we need to liquidate the entire position
            if (minBurnAmount > mintAmount) minBurnAmount = mintAmount;

            // ensure health factor is above liquidation threshold + min health factor delta after liquidation, e.g., 150% + 10% = 160%
            if (burnAmount < minBurnAmount) {
                revert InvalidValue(IVault.ErrorCode.HEALTH_FACTOR_BELOW_MINIMUM);
            }
            // ensure health factor is below liquidation threshold + max health factor delta after liquidation, e.g., 150% + 30% = 180%
            if (
                burnAmount
                    > LiquidationLib.tokensRequiredForTargetHealthFactor(
                        healthFactor_, liquidation.threshold + liquidation.maxHealthFactor, mintAmount, liquidation.penalty
                    )
            ) {
                revert InvalidValue(IVault.ErrorCode.HEALTH_FACTOR_ABOVE_MAXIMUM);
            }
        }

        pocket.withdraw(user, liquidationReward, msg.sender);
        TCAPV2.burn(msg.sender, burnAmount);
        emit Liquidated(msg.sender, user, pocketId, liquidationReward, burnAmount);
    }

    /// @inheritdoc IVault
    function healthFactor(address user, uint96 pocketId) public view returns (uint256) {
        return
            LiquidationLib.healthFactor(mintedAmountOf(user, pocketId), TCAPV2.latestPrice(), collateralOf(user, pocketId), latestPrice(), COLLATERAL_DECIMALS);
    }

    /// @inheritdoc IVault
    function collateralValueOf(uint256 amount) public view returns (uint256) {
        return amount * latestPrice() / 10 ** COLLATERAL_DECIMALS;
    }

    /// @inheritdoc IVault
    function collateralValueOfUser(address user, uint96 pocketId) public view returns (uint256) {
        return collateralValueOf(collateralOf(user, pocketId));
    }

    /// @inheritdoc IVault
    function mintedValueOf(uint256 amount) public view returns (uint256) {
        return TCAPV2.latestPriceOf(amount);
    }

    /// @inheritdoc IVault
    function mintedValueOfUser(address user, uint96 pocketId) external view returns (uint256) {
        return mintedValueOf(mintedAmountOf(user, pocketId));
    }

    /// @inheritdoc IVault
    function collateralOf(address user, uint96 pocketId) public view returns (uint256) {
        IPocket pocket = _getVaultStorage().pockets[pocketId].pocket;
        return pocket.balanceOf(user) - outstandingInterestOf(user, pocketId);
    }

    /// @inheritdoc IVault
    function mintedAmountOf(address user, uint96 pocketId) public view returns (uint256) {
        return _getVaultStorage().mintData.deposits[_toMintId(user, pocketId)].mintAmount;
    }

    /// @inheritdoc IVault
    function outstandingInterestOf(address user, uint96 pocketId) public view returns (uint256) {
        MintData storage $ = _getVaultStorage().mintData;
        uint256 interestAmount = $.interestOf(_toMintId(user, pocketId));
        return interestAmount * TCAPV2.latestPrice() / latestPrice() * 10 ** COLLATERAL_DECIMALS / 10 ** Constants.TCAP_DECIMALS;
    }

    /// @inheritdoc IVault
    function latestPrice() public view returns (uint256) {
        return _getVaultStorage().oracle.latestPrice();
    }

    /// @inheritdoc IVault
    function oracle() external view returns (address) {
        return address(_getVaultStorage().oracle);
    }

    /// @inheritdoc IVault
    function interestRate() external view returns (uint16) {
        return _getVaultStorage().mintData.feeData.fee;
    }

    /// @inheritdoc IVault
    function feeRecipient() external view returns (address) {
        return _getVaultStorage().feeRecipient;
    }

    /// @inheritdoc IVault
    function liquidationParams() public view returns (IVault.LiquidationParams memory params) {
        params = _getVaultStorage().liquidationParams;
    }

    /// @inheritdoc IVault
    function pockets(uint96 id) external view returns (IPocket) {
        return _getVaultStorage().pockets[id].pocket;
    }

    /// @inheritdoc IVault
    function pocketEnabled(uint96 id) external view returns (bool) {
        return _getVaultStorage().pockets[id].enabled;
    }

    function _takeFee(IPocket pocket, address user, uint96 pocketId) internal {
        uint256 interest = outstandingInterestOf(user, pocketId);
        uint256 collateral = collateralOf(user, pocketId);
        if (interest > collateral) interest = collateral;
        VaultStorage storage $ = _getVaultStorage();
        address feeRecipient_ = $.feeRecipient;
        if (interest != 0 && feeRecipient_ != address(0)) {
            pocket.withdraw(user, interest, feeRecipient_);
        }
        $.mintData.resetInterestOf(_toMintId(user, pocketId));
    }

    function _updateInterestRate(uint16 fee) internal {
        if (fee > Constants.MAX_FEE) revert InvalidValue(IVault.ErrorCode.MAX_FEE);
        VaultStorage storage $ = _getVaultStorage();
        $.mintData.setInterestRate(fee);
        emit InterestRateUpdated(fee);
    }

    function _updateFeeRecipient(address newFeeRecipient) internal {
        VaultStorage storage $ = _getVaultStorage();
        $.feeRecipient = newFeeRecipient;
        emit FeeRecipientUpdated(newFeeRecipient);
    }

    function _updateLiquidationParams(IVault.LiquidationParams calldata liquidation) internal {
        if (liquidation.penalty > Constants.MAX_LIQUIDATION_PENALTY) revert InvalidValue(IVault.ErrorCode.MAX_LIQUIDATION_PENALTY);
        if (liquidation.threshold > Constants.MAX_LIQUIDATION_THRESHOLD - liquidation.penalty) revert InvalidValue(IVault.ErrorCode.MAX_LIQUIDATION_THRESHOLD);
        if (liquidation.threshold < Constants.MIN_LIQUIDATION_THRESHOLD + liquidation.penalty) {
            revert InvalidValue(IVault.ErrorCode.MIN_LIQUIDATION_THRESHOLD);
        }
        if (liquidation.minHealthFactor < Constants.MIN_POST_LIQUIDATION_HEALTH_FACTOR) {
            revert InvalidValue(IVault.ErrorCode.MIN_POST_LIQUIDATION_HEALTH_FACTOR);
        }
        if (liquidation.maxHealthFactor > Constants.MAX_POST_LIQUIDATION_HEALTH_FACTOR) {
            revert InvalidValue(IVault.ErrorCode.MAX_POST_LIQUIDATION_HEALTH_FACTOR);
        }
        if (liquidation.minHealthFactor >= liquidation.maxHealthFactor) {
            revert InvalidValue(IVault.ErrorCode.INCOMPATIBLE_MAX_POST_LIQUIDATION_HEALTH_FACTOR);
        }
        VaultStorage storage $ = _getVaultStorage();
        $.liquidationParams = liquidation;
        emit LiquidationParamsUpdated(liquidation);
    }

    function _updateOracle(address newOracle) internal {
        if (IOracle(newOracle).asset() != address(COLLATERAL)) revert IOracle.InvalidOracle();
        VaultStorage storage $ = _getVaultStorage();
        $.oracle = IOracle(newOracle);
        emit OracleUpdated(newOracle);
    }

    function _getPocket(uint96 pocketId) internal view returns (IPocket) {
        Pocket storage p = _getVaultStorage().pockets[pocketId];
        if (!p.enabled) revert PocketNotEnabled(pocketId);
        return p.pocket;
    }

    function _toMintId(address user, uint96 pocketId) internal pure returns (uint256) {
        return uint256(keccak256(abi.encode(user, pocketId)));
    }

    /// @inheritdoc IVersioned
    function version() public pure returns (string memory) {
        return "1.0.0";
    }
}
