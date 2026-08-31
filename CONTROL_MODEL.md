# Vault Coin control model

This file defines the approved administrative boundaries for the simplified
Vault Coin contract.

## Initial state

- The deployment transaction sender becomes the owner.
- The owner receives the complete 100,000,000 VLT initial supply.
- No separate treasury role exists in the contract.

## Owner authority

The current owner can:

- mint any amount of new VLT to any non-zero address;
- transfer ownership to a non-zero address; and
- renounce ownership permanently.

Minting is uncapped. Token holders must trust the owner not to create supply
outside the project's disclosed policy.

## Powers the owner does not have

The owner cannot:

- burn tokens from a holder;
- pause transfers;
- freeze or blacklist an account;
- seize or redirect a holder's balance;
- change allowances without the holder's approval;
- upgrade the deployed contract; or
- change the name, symbol, or decimals.

## Ownership lifecycle

OpenZeppelin Ownable uses immediate ownership transfer. It is not the two-step
Ownable2Step model. The current owner must independently verify a new owner
address before calling transferOwnership.

Renouncing ownership sets the owner to the zero address. This cannot be reversed
through the contract. Existing balances and ordinary ERC-20 transfers continue,
but no account can call mint afterward.

## Deployment boundary

The deployment address is selected outside the contract by the connected Remix
wallet or the Foundry signer. A deployment from an unintended account assigns
both control and the initial supply to that account.
