// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title Vault Coin
/// @notice A minimal ERC-20 with owner-controlled minting.
/// @dev The deployer becomes the owner and receives the initial supply. Because the
///      owner can mint additional tokens, INITIAL_SUPPLY is not a maximum supply.
contract VaultCoin is ERC20, Ownable {
    uint256 public constant INITIAL_SUPPLY = 100_000_000 ether;

    constructor() ERC20("Vault Coin", "VLT") Ownable(msg.sender) {
        _mint(msg.sender, INITIAL_SUPPLY);
    }

    /// @notice Creates `amount` tokens for `to`.
    /// @dev Only the current owner can call this function. OpenZeppelin ERC20 rejects
    ///      the zero address and emits the standard Transfer event from address(0).
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}
