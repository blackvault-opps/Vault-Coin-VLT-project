# Vault Coin (VLT)

Vault Coin is a minimal, owner-mintable ERC-20 built with OpenZeppelin Contracts.
The project is under pre-deployment review and is **not deployed**.

## Approved design

| Property | Value |
|---|---|
| Name | Vault Coin |
| Symbol | VLT |
| Decimals | 18 |
| Initial supply | 100,000,000 VLT |
| Initial owner | Deploying address |
| Initial recipient | Deploying address |
| Additional supply | Current owner may mint |
| Supply cap | None |

The 100,000,000 VLT amount is the initial supply, not a fixed maximum. Each
successful owner mint increases the total supply.

## Included behavior

- Standard ERC-20 transfers, balances, approvals, and transferFrom
- Owner-only mint(address to, uint256 amount)
- Standard OpenZeppelin ownership transfer and renunciation
- Standard ERC-20 and ownership events and custom errors

## Intentionally excluded

- Burning
- Pausing
- EIP-2612 permit
- Proxy or upgrade mechanisms
- Taxes, fees, blacklists, account freezing, or balance seizure
- Role-based access control or governance

OpenZeppelin Ownable allows the owner to renounce ownership. Renunciation is
irreversible and permanently disables future owner-only minting. Ordinary ERC-20
transfers continue after renunciation.

## Repository layout

- src/VaultCoin.sol — token contract
- test/VaultCoin.t.sol — contract behavior and authorization tests
- script/DeployVaultCoin.s.sol — Foundry deployment script
- docs/DEPLOYMENT.md — review, simulation, and deployment procedure
- CONTROL_MODEL.md — owner authority and trust boundaries
- REVIEW_AUDIT.md — implementation and validation record
- SECURITY.md — security considerations and reporting policy

## Toolchain

- Solidity 0.8.24
- OpenZeppelin Contracts v5.0.2
- forge-std v1.9.6
- Foundry v1.8.1

## Install and validate

~~~bash
forge install OpenZeppelin/openzeppelin-contracts@v5.0.2 --no-commit
forge install foundry-rs/forge-std@v1.9.6 --no-commit
forge fmt --check
forge build --sizes
forge test -vvv
~~~

## Remix review

1. Open src/VaultCoin.sol in Remix.
2. Select Solidity compiler 0.8.24.
3. Compile VaultCoin.sol.
4. Review the compiled ABI and bytecode.
5. When separately authorized to deploy, use the connected deployment account.
   The constructor takes no arguments; that account becomes owner and receives
   the initial 100,000,000 VLT.

See docs/DEPLOYMENT.md before any testnet or mainnet transaction.

## Deployment status

No contract address or deployment transaction is recorded. A build, simulation,
or pull request is not a blockchain deployment.

## Important notice

This repository is not an independent security audit or a claim of production
readiness. Owner minting is a powerful and uncapped administrative capability.
Obtain independent technical, operational, and legal review before assigning
real economic value. Never commit private keys, seed phrases, RPC credentials,
keystore passwords, or API keys.
