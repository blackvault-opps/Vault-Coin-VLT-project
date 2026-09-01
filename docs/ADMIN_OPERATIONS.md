# Administrative operations and warnings

These functions can override ordinary holder expectations. Every Safe signer should
review the complete calldata, target network, proxy address and effect before approval.

## Forced burn

`adminBurn(account, amount, reasonHash)` destroys the stated amount without holder
allowance and charges an additional VLT fee to the configured fee recipient.

Required checks:

1. Confirm the proxy address and network.
2. Confirm the full target address and target balance.
3. Confirm the burn amount in 18-decimal base units.
4. Calculate and disclose the additional fee with `adminBurnFee(amount)`.
5. Store the supporting decision/evidence outside the chain.
6. Hash that record and use the nonzero hash as `reasonHash`.
7. Obtain the Safe threshold and inspect the resulting event.

The reason hash proves only that a value was recorded. It does not prove that the
underlying reason was truthful, lawful or warranted.

## Seizure

`seize(from, amount, to, reasonHash)` transfers VLT without allowance and may send it to
any nonzero address. Verify both complete addresses. This action bypasses pause and
blacklist restrictions and does not reduce total supply.

## Pause

Pause stops ordinary transfer, mint and holder-burn operations. Administrative burn and
seizure remain available. Before unpausing, review every blacklist entry and any incident
response action performed during the pause.

## Blacklist

Blacklisting prevents ordinary sending, receiving, minting, burning and allowance use.
It does not prevent the owner from applying forced burn or seizure. Log the reason for
both blocking and unblocking an account.

## Fee changes

`setAdminBurnFeeBps` accepts 1 through 10,000 basis points. At 10,000 bps, the fee equals
the burned amount, so a target losing 100 VLT to burn would also transfer 100 VLT as the
fee. Fee changes are economically material and should be publicly disclosed before use.

`setFeeRecipient` changes where future forced-burn fees are sent. It does not transfer
fees already collected.

## Ownership warning

Zero-owner renunciation is disabled. `renounceOwnership(successor)` does not abandon the
contract; it nominates a deployed successor contract/Safe. The current owner remains in
control until that successor calls `acceptOwnership()`.

## Recovery warning

Recovery moves only assets held by the VLT proxy to the current owner. It cannot recover
assets controlled by a lost user key. VLT held by the proxy uses the reason-hash seizure
path rather than `recoverERC20`.
