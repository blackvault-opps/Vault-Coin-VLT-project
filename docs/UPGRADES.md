# UUPS upgrade procedure

Vault Coin uses an ERC-1967 proxy with upgrade logic in the implementation. The owner
Safe is the only account authorized by `_authorizeUpgrade`.

## Material risk

An authorized upgrade can change every VLT rule, including balances, transfer behavior,
administrative powers and the 420,000,000 VLT governance-protected cap. UUPS capability
is therefore equivalent to broad control over future token behavior.

## Required review before proposing an upgrade

1. Freeze and independently review the proposed implementation source.
2. Confirm it retains UUPS compatibility and owner-only `_authorizeUpgrade`.
3. Confirm the implementation constructor disables initializers.
4. Compare storage namespaces and layouts against the active implementation.
5. Run initializer/reinitializer, non-owner and invalid-implementation tests.
6. Run an upgrade rehearsal preserving owner, pending owner, balances, allowances,
   total supply, cumulative issuance, fee settings, blacklist and paused state.
7. Run formatting, warning-denied lint, size build, unit/fuzz/invariant tests and CI.
8. Verify implementation bytecode and source before preparing Safe calldata.
9. Record whether the implementation preserves the 420M lifetime issuance policy.
10. Obtain a separate written authorization for the exact proxy, implementation,
    network and calldata.

## Execution boundary

The Safe should call `upgradeToAndCall(newImplementation, data)` on the **proxy**. Never
send an upgrade call to the implementation address. Do not execute an upgrade solely
because it compiled or passed unit tests.

After execution, verify the ERC-1967 implementation slot, implementation source,
`implementationVersion`, owner and all preserved state. Retain the transaction hash and
review evidence.
