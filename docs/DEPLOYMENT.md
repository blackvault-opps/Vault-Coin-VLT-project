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

~~~bash
forge install OpenZeppelin/openzeppelin-contracts@v5.0.2 --no-commit
forge install OpenZeppelin/openzeppelin-contracts-upgradeable@v5.0.2 --no-commit
forge install foundry-rs/forge-std@v1.9.6 --no-commit
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
