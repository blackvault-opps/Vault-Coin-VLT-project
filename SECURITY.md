# Security policy

Vault Coin is under pre-deployment review and has not been deployed.

## Reporting a vulnerability

Do not disclose exploitable findings in a public issue. Use GitHub private vulnerability
reporting when available. Include the affected commit, reproduction steps, expected
impact and a proposed correction if known.

## Trust and centralization risks

The owner Safe can:

- mint up to the remaining 420M lifetime issuance ceiling;
- halt ordinary token movement;
- blacklist any account;
- destroy a holder's VLT without allowance and charge an additional fee;
- confiscate and redirect a holder's VLT;
- change the forced-burn fee and recipient;
- recover proxy-held assets; and
- replace the implementation.

Administrative burn and seizure bypass pause and blacklist restrictions. Compromise or
misuse of the owner Safe can therefore cause direct holder loss. A reason hash and event
improve traceability but do not prevent abuse.

The cap is enforced by V1 and by its tests, but a future owner-approved upgrade can
technically change it. The contract cannot enforce off-chain governance promises against
an implementation replacement.

## Technical safeguards

- Atomic proxy initialization
- Locked standalone implementation
- Owner-only UUPS authorization
- ERC-7201 namespaced custom storage
- Two-step ownership acceptance
- Zero-owner renunciation prohibited
- Lifetime cumulative-mint accounting
- Mandatory reason hashes for forced burn and seizure
- Reentrancy protection on external asset recovery
- Pinned compiler, dependency and Foundry versions
- Unit, fuzz, invariant, deployment and upgrade-state tests

## Operational safeguards

- Confirm the Safe owner set and threshold independently before deployment or upgrades.
- Review the exact proxy calldata displayed by every signer.
- Never commit private keys, seed phrases, passwords, RPC credentials or API secrets.
- Exercise privileged controls on Sepolia before any separately approved mainnet use.
- Publish admin-burn fee changes and the existence of blacklist/confiscation controls.
- Independently review the exact commit and deployed bytecode.

Repository tests and CI are not substitutes for an independent smart-contract security
assessment or jurisdiction-specific legal review.
