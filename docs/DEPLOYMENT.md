# Vault Coin deployment guide

Vault Coin is not deployed by this repository. The approved architecture deploys a
`VaultCoin` implementation and an ERC-1967 proxy initialized atomically.

Users and integrations must use the **proxy address**, not the implementation address.
The implementation is locked against initialization in its constructor.

## Fixed deployment configuration

| Parameter | Value |
|---|---|
| Owner | `0xc1cC3138699e07B6d7b990DBa8fAE30b332a1eA6` |
| Initial recipient | Same owner Safe |
| Fee recipient | Same owner Safe |
| Initial supply | 100,000,000 VLT |
| Lifetime ceiling | 420,000,000 VLT |
| Initial admin-burn fee | 100 bps (1%) |

The deployment script hardcodes the confirmed Safe and verifies the initialized owner,
balance, total supply and cumulative issuance before returning.

## Pinned source dependencies

The dependency commits are recorded as Git submodules and in `foundry.lock`.

~~~bash
git submodule update --init
~~~

## Required local validation

~~~bash
forge fmt --check
forge lint --deny warnings
forge build --sizes
forge test -vvv
forge inspect VaultCoin abi
~~~

All commands must pass on the exact proposed commit. Review the ABI and confirm the
presence and exact meaning of mint, pause, blacklist, burn, forced burn, seizure,
recovery, ownership and upgrade functions.

## Non-broadcast simulation

A local script run without `--broadcast` creates no blockchain transaction:

~~~bash
forge script script/DeployVaultCoin.s.sol:DeployVaultCoin -vvv
~~~

A network simulation should use a separately selected public endpoint and still omit
`--broadcast`:

~~~bash
forge script script/DeployVaultCoin.s.sol:DeployVaultCoin --rpc-url "$RPC_URL" -vvv
~~~

Do not paste a private key, seed phrase, Safe signer secret or funded RPC credential into
chat, source files, command history or `.env.example`. A Safe has no single private key.
Use a supported hardware wallet, encrypted keystore or approved wallet flow for any
separately authorized broadcast.

## Pre-broadcast gate

Before Sepolia or mainnet broadcast, independently confirm:

- the final commit and passing CI;
- the full Safe address and deployed Safe bytecode on the target chain;
- current Safe owners and threshold;
- chain ID: Sepolia 11155111 or Ethereum mainnet 1;
- deployer/proposer wallet and estimated fees;
- the 1% initial administrative-burn fee;
- implementation and proxy verification procedure;
- independent security and legal review status; and
- separate written deployment authorization for the exact network.

No merge authorization is also implied by deployment authorization, or vice versa.

## Post-deployment verification

Record the network, chain ID, transaction hash, deployer, implementation address, proxy
address, source commit, compiler settings and explorer links. Query the proxy:

~~~bash
cast call PROXY_ADDRESS "name()(string)" --rpc-url "$RPC_URL"
cast call PROXY_ADDRESS "symbol()(string)" --rpc-url "$RPC_URL"
cast call PROXY_ADDRESS "owner()(address)" --rpc-url "$RPC_URL"
cast call PROXY_ADDRESS "feeRecipient()(address)" --rpc-url "$RPC_URL"
cast call PROXY_ADDRESS "totalSupply()(uint256)" --rpc-url "$RPC_URL"
cast call PROXY_ADDRESS "cumulativeMinted()(uint256)" --rpc-url "$RPC_URL"
cast call PROXY_ADDRESS "MAX_SUPPLY()(uint256)" --rpc-url "$RPC_URL"
cast call PROXY_ADDRESS "adminBurnFeeBps()(uint16)" --rpc-url "$RPC_URL"
cast call PROXY_ADDRESS "paused()(bool)" --rpc-url "$RPC_URL"
cast call PROXY_ADDRESS "implementationVersion()(uint256)" --rpc-url "$RPC_URL"
cast call PROXY_ADDRESS "balanceOf(address)(uint256)" \
  0xc1cC3138699e07B6d7b990DBa8fAE30b332a1eA6 --rpc-url "$RPC_URL"
~~~

Immediately after deployment, `totalSupply`, `cumulativeMinted` and the Safe balance
must each be `100000000000000000000000000` base units. `owner` and `feeRecipient` must
both equal the confirmed Safe, the fee must be 100 bps, and the proxy must be unpaused.

Do not exercise mint, pause, blacklist, forced burn, seizure or upgrade on mainnet as a
verification shortcut. Rehearse those controls on Sepolia under separate authorization.

## Phase 2 — Sepolia preflight and deployment rehearsal

Phase 2 introduces separate local and Sepolia entry points. The generic
`DeployVaultCoin` entry point now accepts only Foundry's local chain ID (`31337`). This
prevents it from being used accidentally for a live network. Sepolia deployment must
use the Sepolia-gated script.

### Read-only Safe preflight

~~~bash
DEPLOYER_ADDRESS=0xPUBLIC_DEPLOYER_ADDRESS \
forge script script/SepoliaPreflight.s.sol:SepoliaPreflight \
  --rpc-url "$SEPOLIA_RPC" -vvvv
~~~

The deployer address is optional and public. The script requires chain ID `11155111`,
deployed bytecode at the confirmed Safe, four distinct nonzero Safe owners and threshold
three. It does not create a contract, sign a transaction or broadcast state changes.

The repository's `Sepolia Read-Only Preflight` GitHub Actions workflow runs this check
only when manually triggered. Normal pull-request and push CI remains deterministic and
does not contact an RPC endpoint.

### Local deployment simulation

~~~bash
forge script script/DeployVaultCoin.s.sol:DeployVaultCoin -vvvv
~~~

### Sepolia fork simulation and gas estimate

~~~bash
forge script script/DeployVaultCoinSepolia.s.sol:DeployVaultCoinSepolia \
  --rpc-url "$SEPOLIA_RPC" --sender 0xPUBLIC_DEPLOYER_ADDRESS -vvvv
~~~

Omit `--broadcast` throughout preflight. Record the implementation deployment gas, proxy
deployment and initialization gas, current fee inputs, and estimated maximum cost in
`docs/SEPOLIA_PREFLIGHT_REPORT.md`.

The 50% funding buffer is advisory. A balance below the simulated maximum transaction
requirement at the selected fee settings is a hard stop. A smaller positive margin may
proceed only under the later, separate authorization for the exact broadcast.

Before any Sepolia broadcast, record a passing CI run for the exact commit and rerun the
read-only Safe preflight and Sepolia simulation against the same RPC. The eventual live
command must be reviewed separately; Phase 2 authorization does not authorize it.
