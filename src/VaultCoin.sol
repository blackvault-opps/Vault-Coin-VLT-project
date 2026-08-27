// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";

/// @title Vault Coin
/// @notice Owner-controlled, pausable, non-burnable ERC-20 test token.
/// @dev The full fixed supply is minted once during construction. No mint or burn
///      function exists after deployment.
contract VaultCoin is ERC20, Ownable, Pausable {
    uint256 public constant INITIAL_SUPPLY = 100_000_000 ether;

    error RenouncingOwnershipDisabled();

    constructor(address initialOwner, address initialRecipient)
        ERC20("Vault Coin", "VLT")
        Ownable(initialOwner)
    {
        if (initialRecipient == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }

        _mint(initialRecipient, INITIAL_SUPPLY);
    }

    /// @notice Stops token transfers until the owner unpauses the contract.
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Resumes token transfers.
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Disabled so the token always retains an accountable owner.
    function renounceOwnership() public view override onlyOwner {
        revert RenouncingOwnershipDisabled();
    }

    /// @dev Applies the pause check to transfers. Constructor minting occurs while
    ///      the contract is unpaused.
    function _update(address from, address to, uint256 value)
        internal
        override
        whenNotPaused
    {
        super._update(from, to, value);
    }
}
