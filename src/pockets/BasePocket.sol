// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IPocket, IVault, IVersioned} from "../interface/pockets/IPocket.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeTransferLib} from "solady/src/utils/SafeTransferLib.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {Constants} from "../lib/Constants.sol";

/// @title Base Pocket
/// @notice The base pocket stores all funds in this contract
/// @dev assumes the underlying token is the same as the overlying token.
contract BasePocket is IPocket, Initializable {
    using SafeTransferLib for address;

    /// @custom:storage-location erc7201:tcapv2.pocket.base
    struct BasePocketStorage {
        uint256 totalShares;
        mapping(address user => uint256 shares) sharesOf;
    }

    // keccak256(abi.encode(uint256(keccak256("tcapv2.pocket.base")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant BasePocketStorageLocation = 0x5845aa409e8f916812e6478a8497f697ddaade604e35f24d88be5edf4ba35300;

    IVault public immutable VAULT;
    IERC20 public immutable UNDERLYING_TOKEN;
    IERC20 public immutable OVERLYING_TOKEN;

    constructor(address vault_, address underlyingToken_, address overlyingToken_) {
        VAULT = IVault(vault_);
        UNDERLYING_TOKEN = IERC20(underlyingToken_);
        OVERLYING_TOKEN = IERC20(overlyingToken_);
        _disableInitializers();
    }

    function initialize() public virtual initializer {}

    function _getBasePocketStorage() private pure returns (BasePocketStorage storage $) {
        assembly {
            $.slot := BasePocketStorageLocation
        }
    }

    modifier onlyVault() {
        if (msg.sender != address(VAULT)) revert Unauthorized();
        _;
    }

    /// @inheritdoc IPocket
    function registerDeposit(address user, uint256 amountUnderlying) external onlyVault returns (uint256 shares) {
        uint256 amountOverlying = _onDeposit(amountUnderlying);
        uint256 totalShares_ = totalShares();
        if (totalShares_ > 0) {
            shares = (totalShares_ * amountOverlying) / (OVERLYING_TOKEN.balanceOf(address(this)) - amountOverlying);
        } else {
            shares = amountOverlying * Constants.DECIMAL_OFFSET;
        }
        if (shares == 0) revert ZeroSharesMinted();
        BasePocketStorage storage $ = _getBasePocketStorage();
        $.totalShares += shares;
        $.sharesOf[user] += shares;
        // @audit should not happen, prevent overflow when calculating balance
        assert($.sharesOf[user] < 1e41);
        emit Deposit(user, amountUnderlying, amountOverlying, shares);
    }

    /// @inheritdoc IPocket
    function withdraw(address user, uint256 amountUnderlying, address recipient) external onlyVault returns (uint256 shares) {
        if (amountUnderlying == type(uint256).max) {
            shares = sharesOf(user);
        } else {
            shares = amountUnderlying * totalShares() / _totalBalance();
        }
        if (shares > sharesOf(user)) revert InsufficientFunds();
        uint256 withdrawnTokens = (shares * OVERLYING_TOKEN.balanceOf(address(this))) / totalShares();
        BasePocketStorage storage $ = _getBasePocketStorage();
        $.sharesOf[user] -= shares;
        $.totalShares -= shares;
        amountUnderlying = _onWithdraw(withdrawnTokens, recipient);
        emit Withdrawal(user, recipient, amountUnderlying, withdrawnTokens, shares);
    }

    /// @inheritdoc IPocket
    function totalShares() public view returns (uint256) {
        return _getBasePocketStorage().totalShares;
    }

    /// @inheritdoc IPocket
    function sharesOf(address user) public view returns (uint256) {
        return _getBasePocketStorage().sharesOf[user];
    }

    /// @inheritdoc IPocket
    function balanceOf(address user) public view returns (uint256) {
        return _balanceOf(user);
    }

    /// @inheritdoc IPocket
    function totalBalance() public view returns (uint256) {
        return _totalBalance();
    }

    function _onDeposit(uint256 amountUnderlying) internal virtual returns (uint256 amountOverlying) {
        amountOverlying = amountUnderlying;
    }

    function _onWithdraw(uint256 amountOverlying, address recipient) internal virtual returns (uint256 amountUnderlying) {
        amountUnderlying = amountOverlying;
        address(UNDERLYING_TOKEN).safeTransfer(recipient, amountUnderlying);
    }

    function _balanceOf(address user) internal view virtual returns (uint256) {
        uint256 totalShares_ = totalShares();
        if (totalShares_ == 0) return 0;
        return sharesOf(user) * OVERLYING_TOKEN.balanceOf(address(this)) / totalShares_;
    }

    function _totalBalance() internal view virtual returns (uint256) {
        return OVERLYING_TOKEN.balanceOf(address(this));
    }

    /// @inheritdoc IVersioned
    function version() external pure virtual override returns (string memory) {
        return "1.0.0";
    }
}
