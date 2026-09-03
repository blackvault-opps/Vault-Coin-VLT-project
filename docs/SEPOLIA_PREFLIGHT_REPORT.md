# Sepolia Preflight Report (Phase 2)

**Status:** Repository validation complete; live Sepolia checks and fork simulation pending  
**Prepared:** September 3, 2026 (UTC)

Record only public, non-secret deployment information. Never record a complete RPC URL,
private key, seed phrase, keystore password or hardware-wallet recovery material.

## Source and validation

- Source commit: [`25ec6bcac34468d20edcec0562122931e995d309`](https://github.com/blackvault-opps/Vault-Coin-VLT-project/commit/25ec6bcac34468d20edcec0562122931e995d309)
- Merged pull request: [PR #5 — Harden VLT controls and Sepolia preflight](https://github.com/blackvault-opps/Vault-Coin-VLT-project/pull/5)
- Post-merge CI: [Foundry CI run #17](https://github.com/blackvault-opps/Vault-Coin-VLT-project/actions/runs/33705067502) — passed
- Foundry version: v1.8.1, commit `982849d3140c01fd3b72905759581a132df7aa98`
- Formatting, lint and build: passed; lint completed with zero warnings
- Unit/fuzz/invariant tests: 53 passed, 0 failed, 0 skipped; fuzz 256 runs;
  invariants 256 runs and 128,000 calls with 0 reverts
- VaultCoin coverage: 96.61% lines (114/118), 97.71% statements (128/131),
  85.00% branches (17/20), 96.30% functions (26/27)
- ABI inspection: passed
- Local deployment rehearsal: passed; reported script gas 2,937,846 on the local
  Foundry chain. This is not a Sepolia gas estimate. No RPC or broadcast was used.

## Read-only Sepolia checks

- RPC provider name only: **PENDING**
- Chain ID: target `11155111`; live confirmation **PENDING**
- Confirmed Safe: `0xc1cC3138699e07B6d7b990DBa8fAE30b332a1eA6`
- Safe bytecode present: **PENDING**
- Safe owners (public addresses): **PENDING**
- Safe owners are nonzero and unique: **PENDING**
- Safe threshold: expected `3-of-4`; live confirmation **PENDING**
- Deployer public address: **PENDING**
- Deployer Sepolia ETH balance: **PENDING**

## Gas and funding

- Implementation deployment gas estimate: **PENDING — Sepolia fork simulation**
- Proxy deployment and initialization gas estimate: **PENDING — Sepolia fork simulation**
- Total simulated maximum gas: **PENDING — Sepolia fork simulation**
- Current fee inputs: **PENDING — capture base fee and priority-fee policy at simulation**
- Estimated maximum Sepolia ETH cost: **PENDING**
- Advisory funding target (estimated maximum cost plus 50%): **PENDING**

The local script gas value above must not be used as the funding requirement. The 50%
buffer is advisory. The hard stop is a deployer balance below the simulated maximum
transaction requirement at the selected fee settings.

## Authorization boundary

- Repository merge: authorized and completed through PR #5
- Live read-only Sepolia preflight: not performed for this report
- Sepolia fork simulation: not performed for this report
- Sepolia or mainnet broadcast: not authorized
- Tag or release: not authorized

## Deployment results

- Implementation address: **NOT DEPLOYED**
- Proxy address: **NOT DEPLOYED**
- Transaction hashes: **NONE**
- Explorer verification status: **NOT APPLICABLE**
- Post-deployment invariant results: **NOT APPLICABLE**
- Deviations: none in repository validation; live-network evidence remains pending

No blockchain transaction was broadcast during merge, CI validation or report
preparation.
