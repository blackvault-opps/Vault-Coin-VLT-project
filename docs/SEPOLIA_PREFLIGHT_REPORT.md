# Sepolia Preflight Report (Phase 2)

Record only public, non-secret deployment information. Never record a complete RPC URL,
private key, seed phrase, keystore password or hardware-wallet recovery material.

## Source and validation

- Source commit:
- CI run URL:
- Foundry version:
- Formatting, lint and build:
- Unit/fuzz/invariant tests:
- Coverage summary:
- Local deployment simulation:

## Read-only Sepolia checks

- RPC provider name only:
- Chain ID: `11155111`
- Confirmed Safe: `0xc1cC3138699e07B6d7b990DBa8fAE30b332a1eA6`
- Safe bytecode present:
- Safe owners (public addresses):
- Safe owners are nonzero and unique:
- Safe threshold: `3-of-4`
- Deployer public address:
- Deployer Sepolia ETH balance:

## Gas and funding

- Implementation deployment gas estimate:
- Proxy deployment and initialization gas estimate:
- Total simulated maximum gas:
- Current fee inputs:
- Estimated maximum Sepolia ETH cost:
- Advisory funding target (estimated maximum cost plus 50%):

The 50% buffer is advisory. The hard stop is a deployer balance below the simulated
maximum transaction requirement at the selected fee settings.

## Deployment results (leave blank until separately authorized broadcast)

- Implementation address:
- Proxy address:
- Transaction hashes:
- Explorer verification status:
- Post-deployment invariant results:
- Deviations:

No blockchain transaction was broadcast during preflight:
