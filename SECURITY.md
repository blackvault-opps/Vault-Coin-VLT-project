# Security policy

Vault Coin is under pre-deployment review and has not been deployed.

## Reporting a vulnerability

Do not disclose exploitable findings in a public issue. Use GitHub private
vulnerability reporting when available and include the affected commit,
reproduction steps, expected impact, and a proposed correction if known.

## Control and supply risks

- The current owner has uncapped mint authority.
- Ownership transfer immediately changes mint authority.
- Renouncing ownership is irreversible and permanently disables minting.
- The contract has no pause, blacklist, seizure, recovery, or upgrade mechanism.
- Compromise or loss of the owner account cannot be repaired by this contract.

## Deployment safeguards

- Independently review the exact commit proposed for deployment.
- Confirm the deployment wallet is the intended owner and initial recipient.
- Use a hardware wallet or encrypted keystore where practical.
- Never commit private keys, seed phrases, passwords, RPC credentials, or API keys.
- Verify the chain ID, source, optimizer settings, ABI, bytecode, and explorer
  verification result.
- Test owner minting and ordinary transfers on a test network before considering
  a production deployment.

Repository tests and CI reduce implementation risk but are not a substitute for
an independent smart-contract security assessment.
