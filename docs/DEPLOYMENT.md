# Vault Coin deployment guide

Vault Coin is not deployed by this repository. Merging code, compiling, testing,
or simulating a script does not create an on-chain contract.

## Contract deployment behavior

VaultCoin has a no-argument constructor:

- the transaction sender becomes the owner;
- 100,000,000 VLT is minted to that same address; and
- the owner may mint additional VLT after deployment.

There is no maximum supply. The contract has no burn, pause, permit, proxy, or
upgrade feature.

## Pinned source dependencies

~~~bash
forge install OpenZeppelin/openzeppelin-contracts@v5.0.2 --no-commit
forge install foundry-rs/forge-std@v1.9.6 --no-commit
~~~

## Required local review

~~~bash
forge fmt --check
forge build --sizes
forge test -vvv
forge inspect VaultCoin abi
~~~

All commands must pass on the exact proposed commit. Review the ABI to confirm
that mint is present and burn, pause, permit, and upgrade functions are absent.

## Remix procedure

1. Load src/VaultCoin.sol in Remix.
2. Compile with Solidity 0.8.24 and optimization enabled with 200 runs.
3. Inspect compiler warnings and the generated ABI.
4. Select the intended wallet and network.
5. Verify the wallet is intended to hold both ownership and the initial supply.
6. Confirm the network chain ID in the wallet before submitting anything.
7. Deploy with no constructor arguments only after a separate deployment approval.

Remix uses the connected wallet as the transaction sender. An accidental
deployment from the wrong account assigns both ownership and the initial supply
to that wrong account.

## Foundry simulation

Set only local, uncommitted environment values:

~~~bash
export RPC_URL="https://your-rpc-endpoint.example"
~~~

Run a simulation without --broadcast:

~~~bash
forge script script/DeployVaultCoin.s.sol:DeployVaultCoin --rpc-url "$RPC_URL"
~~~

Inspect the chain ID, sender, created address, owner, initial owner balance, and
total supply. A simulation is not evidence of deployment.

## Broadcast gate

Do not add --broadcast until all of the following are separately approved:

- exact network and chain ID;
- exact deploying/owner address;
- deployment transaction fees;
- final source commit;
- independent review status; and
- post-deployment verification plan.

Use a hardware wallet or encrypted Foundry keystore where practical. Do not place
a funded private key in this repository or its environment example.

## Post-deployment verification

Record the network, chain ID, transaction hash, contract address, deployer/owner,
compiler version, optimizer settings, source commit, and explorer verification
URL. Then verify:

~~~bash
cast call CONTRACT_ADDRESS "name()(string)" --rpc-url "$RPC_URL"
cast call CONTRACT_ADDRESS "symbol()(string)" --rpc-url "$RPC_URL"
cast call CONTRACT_ADDRESS "decimals()(uint8)" --rpc-url "$RPC_URL"
cast call CONTRACT_ADDRESS "totalSupply()(uint256)" --rpc-url "$RPC_URL"
cast call CONTRACT_ADDRESS "owner()(address)" --rpc-url "$RPC_URL"
cast call CONTRACT_ADDRESS "balanceOf(address)(uint256)" OWNER_ADDRESS --rpc-url "$RPC_URL"
~~~

Immediately after deployment, expected total supply and owner balance are both
100000000000000000000000000 base units.

Minting requires the current owner and amounts are supplied in base units. For
example, one VLT is 1000000000000000000 base units.
