// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Ownable2StepUpgradeable} from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {
    ERC20BurnableUpgradeable
} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

/// @title Vault Coin
/// @notice Owner-managed, capped, burnable, pausable and UUPS-upgradeable ERC-20.
/// @dev Administrative burn, seizure, blacklist and upgrade powers are highly privileged.
///      The intended owner is the confirmed Vault Coin multisignature Safe.
contract VaultCoin is
    Initializable,
    ERC20Upgradeable,
    ERC20BurnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    Ownable2StepUpgradeable,
    UUPSUpgradeable
{
    using SafeERC20 for IERC20;

    uint256 public constant INITIAL_SUPPLY = 100_000_000 ether;
    uint256 public constant MAX_SUPPLY = 420_000_000 ether;
    uint16 public constant BPS_DENOMINATOR = 10_000;
    uint16 public constant DEFAULT_ADMIN_BURN_FEE_BPS = 100;

    /// @custom:storage-location erc7201:blackvault.storage.VaultCoin
    struct VaultCoinStorage {
        uint256 cumulativeMinted;
        uint16 adminBurnFeeBps;
        address feeRecipient;
        bool administrativeOperation;
        mapping(address account => bool blocked) blacklisted;
    }

    // keccak256(abi.encode(uint256(keccak256("blackvault.storage.VaultCoin")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant VAULT_COIN_STORAGE_LOCATION =
        0xac2698fa95a160b02b4094c7bd78ca8eb07c425877174f90e4df40b910d38600;

    error AccountBlacklisted(address account);
    error AdministrativeAmountIsZero();
    error FeeBpsOutOfRange(uint256 feeBps);
    error InvalidFeeRecipient(address recipient);
    error InvalidOwnershipSuccessor(address successor);
    error LifetimeSupplyCapExceeded(uint256 attemptedCumulativeMint, uint256 maximumSupply);
    error OwnershipRenunciationRequiresSuccessor();
    error ReasonHashRequired();
    error RecoveryOfVLTRequiresSeizure();

    event AdminBurn(
        address indexed operator,
        address indexed account,
        uint256 burnedAmount,
        uint256 feeAmount,
        address indexed feeRecipient,
        bytes32 reasonHash
    );
    event AdminBurnFeeUpdated(uint16 previousFeeBps, uint16 newFeeBps);
    event BlacklistUpdated(address indexed account, bool blocked, address indexed operator);
    event FeeRecipientUpdated(address indexed previousRecipient, address indexed newRecipient);
    event OwnershipRenunciationInitiated(address indexed currentOwner, address indexed requiredSuccessor);
    event Seized(
        address indexed operator, address indexed from, address indexed to, uint256 amount, bytes32 reasonHash
    );
    event ERC20Recovered(address indexed token, address indexed recipient, uint256 amount);
    event ETHRecovered(address indexed recipient, uint256 amount);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice Initializes the proxy and sends the initial supply to `initialOwner`.
    /// @param initialOwner The nonzero Safe that receives ownership and 100,000,000 VLT.
    /// @param initialFeeRecipient The nonzero treasury that receives administrative-burn fees.
    /// @param initialAdminBurnFeeBps Administrative-burn fee from 1 to 10,000 basis points.
    function initialize(address initialOwner, address initialFeeRecipient, uint16 initialAdminBurnFeeBps)
        external
        initializer
    {
        if (initialFeeRecipient == address(0)) {
            revert InvalidFeeRecipient(address(0));
        }
        _validateFeeBps(initialAdminBurnFeeBps);

        __ERC20_init("Vault Coin", "VLT");
        __ERC20Burnable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        __Ownable_init(initialOwner);
        __Ownable2Step_init();
        __UUPSUpgradeable_init();

        VaultCoinStorage storage $ = _getVaultCoinStorage();
        $.feeRecipient = initialFeeRecipient;
        $.adminBurnFeeBps = initialAdminBurnFeeBps;
        _mint(initialOwner, INITIAL_SUPPLY);
    }

    receive() external payable {}

    function implementationVersion() public pure virtual returns (uint256) {
        return 1;
    }

    /// @notice Returns all VLT ever minted. Burning does not decrease this value.
    function cumulativeMinted() public view returns (uint256) {
        return _getVaultCoinStorage().cumulativeMinted;
    }

    function adminBurnFeeBps() public view returns (uint16) {
        return _getVaultCoinStorage().adminBurnFeeBps;
    }

    function feeRecipient() public view returns (address) {
        return _getVaultCoinStorage().feeRecipient;
    }

    function isBlacklisted(address account) public view returns (bool) {
        return _getVaultCoinStorage().blacklisted[account];
    }

    /// @notice Returns the additional VLT charged for an administrative burn.
    function adminBurnFee(uint256 amount) public view returns (uint256) {
        return Math.mulDiv(amount, adminBurnFeeBps(), BPS_DENOMINATOR, Math.Rounding.Ceil);
    }

    /// @notice Mints VLT while cumulative lifetime issuance remains at or below 420,000,000 VLT.
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Blocks or unblocks ordinary transfers, receipt, minting, burning and approvals for `account`.
    /// @dev Owner-only seizure and administrative burn deliberately bypass blacklist restrictions.
    function blacklist(address account, bool blocked) external onlyOwner {
        if (account == address(0) || account == address(this)) {
            revert AccountBlacklisted(account);
        }
        VaultCoinStorage storage $ = _getVaultCoinStorage();
        $.blacklisted[account] = blocked;
        // forge-lint: disable-next-line(reentrancy-events)
        emit BlacklistUpdated(account, blocked, msg.sender);
    }

    /// @notice Sets the additional administrative-burn fee. One percent is 100 basis points.
    /// @dev WARNING: The fee is taken from the target in addition to the amount destroyed.
    function setAdminBurnFeeBps(uint16 newFeeBps) external onlyOwner {
        _validateFeeBps(newFeeBps);
        VaultCoinStorage storage $ = _getVaultCoinStorage();
        uint16 previousFeeBps = $.adminBurnFeeBps;
        $.adminBurnFeeBps = newFeeBps;
        // forge-lint: disable-next-line(reentrancy-events)
        emit AdminBurnFeeUpdated(previousFeeBps, newFeeBps);
    }

    function setFeeRecipient(address newRecipient) external onlyOwner {
        if (newRecipient == address(0)) revert InvalidFeeRecipient(address(0));
        VaultCoinStorage storage $ = _getVaultCoinStorage();
        address previousRecipient = $.feeRecipient;
        $.feeRecipient = newRecipient;
        // forge-lint: disable-next-line(reentrancy-events)
        emit FeeRecipientUpdated(previousRecipient, newRecipient);
    }

    /// @notice WARNING: Forcibly destroys `amount` VLT from `account` without an allowance.
    /// @dev The account must hold `amount + fee`. A nonzero evidence/reason hash is mandatory.
    ///      The fee is transferred to the configured treasury and the requested amount is burned.
    ///      This function works while paused and for blacklisted accounts.
    function adminBurn(address account, uint256 amount, bytes32 reasonHash) external onlyOwner {
        if (amount == 0) revert AdministrativeAmountIsZero();
        if (reasonHash == bytes32(0)) revert ReasonHashRequired();

        VaultCoinStorage storage $ = _getVaultCoinStorage();
        uint256 fee = adminBurnFee(amount);
        $.administrativeOperation = true;
        _transfer(account, $.feeRecipient, fee);
        _burn(account, amount);
        $.administrativeOperation = false;

        // forge-lint: disable-next-line(reentrancy-events)
        emit AdminBurn(msg.sender, account, amount, fee, $.feeRecipient, reasonHash);
    }

    /// @notice WARNING: Forcibly transfers VLT without holder approval.
    /// @dev A nonzero evidence/reason hash is mandatory. This operation bypasses pause and blacklist restrictions.
    function seize(address from, uint256 amount, address to, bytes32 reasonHash) external onlyOwner {
        if (amount == 0) revert AdministrativeAmountIsZero();
        if (reasonHash == bytes32(0)) revert ReasonHashRequired();

        VaultCoinStorage storage $ = _getVaultCoinStorage();
        $.administrativeOperation = true;
        _transfer(from, to, amount);
        $.administrativeOperation = false;
        // forge-lint: disable-next-line(reentrancy-events)
        emit Seized(msg.sender, from, to, amount, reasonHash);
    }

    /// @notice Recovers an unrelated ERC-20 accidentally held by the VLT proxy to the current owner.
    /// @dev VLT held by this proxy must be recovered through `seize` so the action receives a reason hash.
    function recoverERC20(address token, uint256 amount) external nonReentrant onlyOwner {
        if (token == address(this)) revert RecoveryOfVLTRequiresSeizure();
        address recipient = owner();
        IERC20(token).safeTransfer(recipient, amount);
        // forge-lint: disable-next-line(reentrancy-events)
        emit ERC20Recovered(token, recipient, amount);
    }

    /// @notice Recovers native ETH accidentally held by the VLT proxy to the current owner.
    // forge-lint: disable-next-line(mixed-case-function)
    function recoverETH(uint256 amount) external nonReentrant onlyOwner {
        address recipient = owner();
        // forge-lint: disable-next-line(arbitrary-send-eth)
        Address.sendValue(payable(recipient), amount);
        // forge-lint: disable-next-line(reentrancy-events)
        emit ETHRecovered(recipient, amount);
    }

    /// @notice WARNING: Zero-owner renunciation is prohibited because it would strand all controls and upgrades.
    function renounceOwnership() public pure override {
        revert OwnershipRenunciationRequiresSuccessor();
    }

    /// @notice Starts a two-step replacement of the owner; authority is never assigned to the zero address.
    /// @dev WARNING: `successor` must explicitly call `acceptOwnership`. The current owner remains active until then.
    function renounceOwnership(address successor) external onlyOwner {
        address currentOwner = owner();
        if (successor == address(0) || successor == currentOwner || successor.code.length == 0) {
            revert InvalidOwnershipSuccessor(successor);
        }
        // forge-lint: disable-next-line(reentrancy-events)
        emit OwnershipRenunciationInitiated(currentOwner, successor);
        transferOwnership(successor);
    }

    /// @notice Starts a two-step ownership transfer to another deployed Safe or contract account.
    function transferOwnership(address newOwner) public override onlyOwner {
        if (newOwner == address(0) || newOwner == owner() || newOwner.code.length == 0) {
            revert InvalidOwnershipSuccessor(newOwner);
        }
        super.transferOwnership(newOwner);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function _update(address from, address to, uint256 value) internal override {
        VaultCoinStorage storage $ = _getVaultCoinStorage();

        if (!$.administrativeOperation) {
            _requireNotPaused();
            if (from != address(0) && $.blacklisted[from]) revert AccountBlacklisted(from);
            if (to != address(0) && $.blacklisted[to]) revert AccountBlacklisted(to);
        }

        if (from == address(0)) {
            uint256 attemptedCumulativeMint = $.cumulativeMinted + value;
            if (attemptedCumulativeMint > MAX_SUPPLY) {
                revert LifetimeSupplyCapExceeded(attemptedCumulativeMint, MAX_SUPPLY);
            }
            $.cumulativeMinted = attemptedCumulativeMint;
        }

        super._update(from, to, value);
    }

    function _approve(address accountOwner, address spender, uint256 value, bool emitEvent) internal override {
        VaultCoinStorage storage $ = _getVaultCoinStorage();
        if ($.blacklisted[accountOwner]) revert AccountBlacklisted(accountOwner);
        if ($.blacklisted[spender]) revert AccountBlacklisted(spender);
        super._approve(accountOwner, spender, value, emitEvent);
    }

    function _validateFeeBps(uint16 feeBps) private pure {
        if (feeBps == 0 || feeBps > BPS_DENOMINATOR) revert FeeBpsOutOfRange(feeBps);
    }

    function _getVaultCoinStorage() private pure returns (VaultCoinStorage storage $) {
        // forge-lint: disable-next-line(inline-assembly)
        assembly ("memory-safe") {
            $.slot := VAULT_COIN_STORAGE_LOCATION
        }
    }
}
