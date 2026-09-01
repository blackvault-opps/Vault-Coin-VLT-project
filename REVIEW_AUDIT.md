# Vault Coin implementation review

**Date:** September 1, 2026

**Repository:** `blackvault-opps/Vault-Coin-VLT-project`

**Implementation branch:** `feature/vaultcoin-controls-uups`

**Branch base:** `75afe8c2eb4448eb357fb457c425b6d2f0d4f437`

**Deployment status:** Not deployed

## Authorized replacement model

- Vault Coin / VLT / 18 decimals
- 100,000,000 VLT initial supply to the confirmed owner Safe
- 420,000,000 VLT lifetime issuance ceiling in V1
- Owner mint, pause, blacklist, forced burn, seizure, recovery and upgrade controls
- Holder `burn` and allowance-based `burnFrom`
- ERC-1967 proxy with UUPS implementation upgrades
- Two-step ownership replacement and no zero-owner state
- No EIP-2612 permit, taxes or reflection behavior

## Implementation mapping

| Requirement | Implementation |
|---|---|
| Initial owner/recipient | Confirmed Safe hardcoded by deployment script |
| Lifetime issuance | `cumulativeMinted` plus 420M `MAX_SUPPLY` |
| Holder burn | OpenZeppelin `ERC20BurnableUpgradeable` |
| Pause | OpenZeppelin `PausableUpgradeable` applied to ordinary movement |
| Blacklist | ERC-7201 namespaced mapping checked in transfer and approval hooks |
| Forced burn | Owner-only, no allowance, added configurable fee, reason hash and event |
| Confiscation | Owner-only transfer to any address, reason hash and event |
| Recovery | Owner-only proxy-held ERC-20/ETH recovery |
| Ownership | `Ownable2StepUpgradeable`; successor must be deployed contract |
| Renunciation | Zero-owner call reverts; successor overload initiates two-step transfer |
| Upgrade | `UUPSUpgradeable`; `_authorizeUpgrade` is owner-only |
| Implementation lock | Constructor calls `_disableInitializers()` |

## Local validation evidence

Pinned local toolchain:

- Foundry v1.8.1, commit `982849d3140c01fd3b72905759581a132df7aa98`
- Solidity 0.8.24
- OpenZeppelin Contracts v5.0.2
- OpenZeppelin Contracts Upgradeable v5.0.2
- forge-std v1.9.6

Validation performed without an RPC endpoint, transaction signature or broadcast:

| Command | Result |
|---|---|
| `forge fmt` / `forge fmt --check` | Passed |
| `forge lint --deny warnings` | Passed; no warnings |
| `forge build --sizes` | Passed |
| `forge test -vvv` | Passed: 41 tests, 0 failed, 0 skipped |
| Fuzz test | Passed: 256 runs |
| Stateful invariants | Passed: 256 runs, 128,000 calls, 0 reverts |
| `forge coverage --report summary` | Passed; 41 tests re-executed |
| Local deployment script test | Passed; implementation and initialized proxy verified |

Production-contract coverage for `src/VaultCoin.sol`:

- Lines: 96.52% (111/115)
- Statements: 97.62% (123/126)
- Branches: 83.33% (15/18)
- Functions: 96.30% (26/27)

The suite covers initialization locking, owner authorization, lifetime cap, ordinary
ERC-20 behavior, holder burns, pause, blacklist, forced burn fees, confiscation,
recovery, two-step replacement, nonzero-owner invariant, invalid upgrades and storage
preservation across a V1-to-V2 UUPS upgrade.

## Known governance and operational risks

- Owner powers are intentionally centralized and can directly alter holder balances.
- Forced burns charge the target an additional fee.
- Seizure can redirect VLT to any owner-selected address.
- Administrative burn and seizure work while paused and against blacklisted accounts.
- The owner can set the forced-burn fee as high as 10,000 bps.
- A future UUPS upgrade can technically alter the cap or any other rule.
- Safe signer and threshold controls exist outside VLT and must be independently checked.

## Review boundary

This report records local implementation evidence. It is not an independent audit,
legal opinion, merge authorization or authorization to deploy. Remote CI must pass on
the pushed commit. Any merge, Sepolia transaction, mainnet transaction or future upgrade
requires its own explicit authorization and verification record.
