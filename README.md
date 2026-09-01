# Vault Coin (VLT)

Vault Coin is an owner-managed ERC-20 using an ERC-1967 proxy and the OpenZeppelin
UUPS upgrade pattern. The project is under pre-deployment review and is **not
deployed**.

## Approved design

| Property | Value |
|---|---|
| Name / symbol / decimals | Vault Coin / VLT / 18 |
| Initial supply | 100,000,000 VLT |
| Lifetime issuance ceiling | 420,000,000 VLT |
| Initial owner and recipient | `0xc1cC3138699e07B6d7b990DBa8fAE30b332a1eA6` |
| Initial admin-burn fee | 100 basis points (1%) |
| Proxy architecture | ERC-1967 with owner-authorized UUPS upgrades |
| Ownership | Two-step transfer to a deployed contract/Safe |
| Zero-owner renunciation | Prohibited |

The 420,000,000 VLT limit is a **lifetime issuance ceiling** in this implementation.
Burning does not reopen mint capacity. Because the owner can replace the UUPS
implementation, a future owner-approved upgrade could technically change or remove
that rule. Preservation of the cap is therefore governance-protected, not immutable.

## Privileged owner controls

The owner can:

- mint within the remaining lifetime issuance ceiling;
- pause and unpause ordinary token movement;
- blacklist and unblacklist accounts;
- forcibly burn a holder's VLT without allowance, plus a configurable VLT fee;
- forcibly transfer VLT from any account to any owner-selected address;
- change the administrative-burn fee and fee recipient;
- recover unrelated ERC-20 tokens and ETH held by the proxy;
- initiate a two-step ownership replacement; and
- authorize implementation upgrades.

Administrative burn and seizure deliberately bypass pause and blacklist restrictions.
Both require a nonzero `reasonHash` and emit permanent events. A reason hash records
the evidence reference selected by the owner; the contract cannot determine whether
an action is legally or factually justified.

At the initial 1% fee, `adminBurn(account, 100 ether, reasonHash)` requires the account
to hold at least 101 VLT. It transfers 1 VLT to the fee recipient and destroys 100 VLT.
It cannot burn a nonexistent or negative balance.

## Holder controls

Holders retain standard ERC-20 transfer and approval behavior plus:

- `burn(amount)` to destroy their own VLT; and
- `burnFrom(account, amount)` to destroy VLT covered by an allowance.

Holder burns do not pay the administrative-burn fee. When paused, ordinary transfers,
minting and holder burning are blocked. Blacklisted accounts cannot send, receive,
mint, burn or participate in approvals.

## Ownership safety

Calling the standard zero-argument `renounceOwnership()` always reverts. The
successor-based overload starts a two-step transfer and leaves the current owner in
control until the successor explicitly calls `acceptOwnership()`. The contract never
intentionally enters a zero-owner state.

The intended owner is the existing non-nested Vault Coin Safe. The separate Safe
`0xB06A1DDcb9b31ecBb1a298C68954220FF96E3a03` and any nested Safe are explicitly
outside this token's authorization model.

## Repository layout

- `src/VaultCoin.sol` — upgradeable token implementation
- `script/DeployVaultCoin.s.sol` — implementation and proxy deployment script
- `test/VaultCoin.t.sol` — unit, fuzz, authorization and upgrade tests
- `test/VaultCoin.invariant.t.sol` — stateful supply and ownership invariants
- `test/DeployVaultCoin.t.sol` — local deployment-script verification
- `CONTROL_MODEL.md` — exact authority and trust boundaries
- `docs/ADMIN_OPERATIONS.md` — warning labels and administrative procedures
- `docs/DEPLOYMENT.md` — simulation and separately authorized deployment procedure
- `docs/UPGRADES.md` — upgrade review and execution controls
- `REVIEW_AUDIT.md` — implementation and validation evidence
- `SECURITY.md` — security assumptions and reporting policy

## Toolchain and validation

- Solidity 0.8.24
- OpenZeppelin Contracts v5.0.2
- OpenZeppelin Contracts Upgradeable v5.0.2
- forge-std v1.9.6
- Foundry v1.8.1

~~~bash
forge install OpenZeppelin/openzeppelin-contracts@v5.0.2 --no-commit
forge install OpenZeppelin/openzeppelin-contracts-upgradeable@v5.0.2 --no-commit
forge install foundry-rs/forge-std@v1.9.6 --no-commit
forge fmt --check
forge lint --deny warnings
forge build --sizes
forge test -vvv
~~~

## Deployment status

No VLT proxy address, implementation address or deployment transaction is recorded.
Compilation, tests, script simulation, a commit or a pull request are not blockchain
deployment evidence. See `docs/DEPLOYMENT.md` before any network transaction.

This repository is not an independent security audit, legal opinion or token-value
representation. The owner controls are unusually powerful and must be disclosed to
holders. Obtain independent technical and legal review before assigning real economic
value.
