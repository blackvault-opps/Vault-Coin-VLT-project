// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {ERC20Pausable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";

/// @title Vault Coin
/// @notice Owner-controlled, pausable, non-burnable ERC-20 test token.
/// @dev The full fixed supply is minted once during construction. No mint or burn
///      function exists after deployment.
contract VaultCoin is ERC20, ERC20Permit, ERC20Pausable, Ownable2Step {
    uint256 public constant INITIAL_SUPPLY = 100_000_000 ether;

    error RenouncingOwnershipDisabled();
    error OwnerMustBeContract(address candidate);
    error TreasuryMustBeContract(address candidate);

    constructor(address initialOwner, address initialTreasury)
        ERC20("Vault Coin", "VLT")
        ERC20Permit("Vault Coin")
        Ownable(initialOwner)
    {
        if (initialOwner.code.length == 0) {
            revert OwnerMustBeContract(initialOwner);
        }
        if (initialTreasury.code.length == 0) {
            revert TreasuryMustBeContract(initialTreasury);
        }

        _mint(initialTreasury, INITIAL_SUPPLY);
    }

    /// @notice Stops token transfers until the owner unpauses the contract.
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Resumes token transfers.
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Starts a two-step ownership transfer to another contract, such as a Safe.
    function transferOwnership(address newOwner) public override onlyOwner {
        if (newOwner.code.length == 0) {
            revert OwnerMustBeContract(newOwner);
        }
        super.transferOwnership(newOwner);
    }

    /// @notice Disabled so the token always retains an accountable owner.
    function renounceOwnership() public view override onlyOwner {
        revert RenouncingOwnershipDisabled();
    }

    /// @dev Resolves the ERC20 and ERC20Pausable implementation paths.
    function _update(address from, address to, uint256 value) internal override(ERC20, ERC20Pausable) {
        super._update(from, to, value);
    }
}
