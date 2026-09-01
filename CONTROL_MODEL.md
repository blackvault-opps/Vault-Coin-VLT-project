# Vault Coin control model

This document defines the VLT proxy's authorized control surface and trust boundaries.

## Authoritative addresses

| Purpose | Address | Treatment |
|---|---|---|
| Initial VLT owner, treasury, fee recipient and supply recipient | `0xc1cC3138699e07B6d7b990DBa8fAE30b332a1eA6` | Authorized |
| Rewards Network personal Safe | `0xB06A1DDcb9b31ecBb1a298C68954220FF96E3a03` | Excluded |
| Any nested Safe shown in prior material | Not applicable | Excluded |

The authorized address is expected to be a 3-of-4 Safe on Ethereum and Sepolia. VLT
only sees one owner address; signer identities, signer count and threshold are enforced
by the Safe rather than by the token contract. Those Safe settings can change through
separately authorized Safe transactions.

## Supply authority

- Initialization mints 100,000,000 VLT to the owner.
- `cumulativeMinted` records all lifetime issuance and never decreases.
- `mint` reverts if lifetime issuance would exceed 420,000,000 VLT.
- Holder burn, allowance burn and administrative burn reduce live `totalSupply` but do
  not reduce `cumulativeMinted` or reopen mint capacity.
- A future UUPS implementation could technically change these rules. Every proposed
  upgrade must demonstrate cap preservation unless a new specification is explicitly
  approved and publicly disclosed.

## Owner authority

| Function | Effect | Holder consent |
|---|---|---|
| `mint` | Creates VLT within remaining lifetime ceiling | Not required |
| `pause` / `unpause` | Stops or resumes ordinary movement | Not required |
| `blacklist` | Blocks/unblocks ordinary account activity | Not required |
| `adminBurn` | Destroys target VLT and charges target a treasury fee | Not required |
| `seize` | Moves target VLT to any selected address | Not required |
| `setAdminBurnFeeBps` | Changes forced-burn fee from 1 to 10,000 bps | Not required |
| `setFeeRecipient` | Changes fee recipient | Not required |
| `recoverERC20` / `recoverETH` | Returns proxy-held assets to current owner | Not required |
| `transferOwnership` | Nominates a successor contract/Safe | Successor must accept |
| `upgradeToAndCall` | Replaces proxy implementation | Not required by VLT |

The external Safe threshold supplies multisignature approval for owner calls. The token
does not independently verify the number of Safe signatures.

## Pause and blacklist rules

Pause blocks ordinary transfers, minting and holder burns. Approvals remain possible
while paused unless an involved account is blacklisted. A blacklisted account cannot:

- send or receive VLT;
- receive newly minted VLT;
- use `burn` or be used in `burnFrom`; or
- grant, receive or consume an allowance.

`adminBurn` and `seize` intentionally bypass pause and blacklist restrictions so the
owner retains emergency enforcement capability. These are explicit centralization and
confiscation powers.

## Administrative burn

`adminBurn(account, amount, reasonHash)`:

1. requires the owner and a nonzero reason hash;
2. computes a fee using `adminBurnFeeBps`, rounded up to the nearest base unit;
3. transfers that fee from the target to `feeRecipient`; and
4. destroys the requested amount from the target.

The target must hold `amount + fee`. No allowance is requested, but no nonexistent
balance can be burned. The initial fee is 100 bps (1%). Holder `burn` and `burnFrom`
remain fee-free.

## Confiscation

`seize(from, amount, to, reasonHash)` transfers VLT from any funded address to any
nonzero owner-selected address without allowance. It requires a nonzero reason hash
and works while paused and against blacklisted accounts.

## Asset recovery

Recovery applies only to assets held by the VLT proxy:

- `recoverERC20` transfers an unrelated ERC-20 from the proxy to the current owner.
- `recoverETH` transfers ETH from the proxy to the current owner.
- VLT held by the proxy must use `seize` so the recovery has a reason hash and seizure
  event.

Recovery cannot restore a user's assets from a lost key or reverse an unrelated chain
transaction.

## Ownership lifecycle

- `transferOwnership(newOwner)` accepts only a deployed contract address and starts a
  two-step transfer.
- The current owner remains active until `newOwner` calls `acceptOwnership()`.
- Zero-owner `renounceOwnership()` always reverts.
- `renounceOwnership(successor)` is a warning-labelled alias that starts the same
  two-step successor process; it does not abandon ownership.
- A zero owner is an invariant of the test suite and is not an authorized state.

## Upgrade authority

The owner exclusively authorizes UUPS upgrades. An upgrade can change any implementation
rule, including administrative powers and the cap. Repository policy, tests, independent
review and Safe approval are therefore part of the control boundary. See
`docs/UPGRADES.md`.
