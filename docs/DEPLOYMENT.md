# Testnet deployment guide

This repository prepares Vault Coin for review and testnet deployment. It does
not deploy automatically and contains no private credentials.

## Prerequisites

Install Foundry, then install the pinned dependencies:

```bash
forge install OpenZeppelin/openzeppelin-contracts@v5.0.2 --no-commit
forge install foundry-rs/forge-std@v1.9.6 --no-commit
```

## Review and test

```bash
forge fmt --check
forge build --sizes
forge test -vvv
```

## Configure locally

Copy `.env.example` to `.env`. Use a dedicated testnet deployer key. Never
commit `.env`.

Required values:

- `RPC_URL`: selected EVM testnet endpoint.
- `PRIVATE_KEY`: funded testnet deployer private key.
- `INITIAL_OWNER`: address authorized to pause, unpause, and transfer ownership.
- `INITIAL_RECIPIENT`: address receiving all 100,000,000 VLT.
- `ETHERSCAN_API_KEY`: optional explorer verification credential.

The owner and recipient may be the same address.

## Simulate before broadcasting

```bash
source .env
forge script script/DeployVaultCoin.s.sol:DeployVaultCoin \
  --rpc-url "$RPC_URL"
```

Inspect the simulation carefully, including the network chain ID, constructor
arguments, deployer balance, owner, recipient, and supply.

## Broadcast to the selected testnet

```bash
forge script script/DeployVaultCoin.s.sol:DeployVaultCoin \
  --rpc-url "$RPC_URL" \
  --broadcast
```

Add `--verify --etherscan-api-key "$ETHERSCAN_API_KEY"` only when the selected
testnet explorer supports Etherscan-compatible verification.

## Post-deployment verification

Record the chain ID, network name, deployment transaction hash, contract address,
compiler version, constructor arguments, owner, initial recipient, and runtime
bytecode hash. Then verify:

```bash
cast call CONTRACT_ADDRESS "name()(string)" --rpc-url "$RPC_URL"
cast call CONTRACT_ADDRESS "symbol()(string)" --rpc-url "$RPC_URL"
cast call CONTRACT_ADDRESS "totalSupply()(uint256)" --rpc-url "$RPC_URL"
cast call CONTRACT_ADDRESS "owner()(address)" --rpc-url "$RPC_URL"
cast call CONTRACT_ADDRESS "paused()(bool)" --rpc-url "$RPC_URL"
```

Expected total supply is `100000000000000000000000000` base units.
