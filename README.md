# Vault Coin (VLT)

Vault Coin is an owner-controlled, non-burnable ERC-20 test token prepared for
review and testnet deployment. The project is **not deployed**.

## Confirmed design

- Name: `Vault Coin`
- Symbol: `VLT`
- Decimals: `18`
- Fixed supply: `100,000,000 VLT`
- Initial distribution: the entire supply is minted once at deployment to the
  constructor's contract-only `initialTreasury`
- Owner: must be a deployed contract, intended to be a Safe multisig
- Owner controls: pause transfers, unpause transfers, and two-step ownership transfer
- Permit: EIP-2612 signed approvals
- No post-deployment mint function
- No burn function
- Ownership renunciation is disabled
- Non-upgradeable implementation

The owner cannot seize balances, freeze individual addresses, change balances,
alter the fixed supply, or upgrade the contract.

## Repository layout

- `src/VaultCoin.sol` — token contract
- `test/VaultCoin.t.sol` — behavior and access-control tests
- `script/DeployVaultCoin.s.sol` — Foundry deployment script
- `docs/DEPLOYMENT.md` — testnet deployment and verification procedure
- `SECURITY.md` — vulnerability reporting and deployment safeguards
- `.github/workflows/ci.yml` — formatting, build, and test checks

## Toolchain

Foundry, Solidity `0.8.24`, OpenZeppelin Contracts `v5.0.2`, and forge-std `v1.9.6`.

## Install and verify

```bash
forge install OpenZeppelin/openzeppelin-contracts@v5.0.2 --no-commit
forge install foundry-rs/forge-std@v1.9.6 --no-commit
forge fmt --check
forge build --sizes
forge test -vvv
```

See [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) for safe testnet deployment steps.

## Deployment status

No contract address or deployment transaction is recorded. Deployment is not
complete until a transaction is broadcast, confirmed on the intended network,
and documented with its chain ID, transaction hash, contract address,
constructor arguments, and verification result.

## Important notice

This is test-token software, not a claim of production readiness. Do not use it
with real economic value without independent technical, operational, and legal
review. Never commit private keys, seed phrases, RPC credentials, or API keys.
