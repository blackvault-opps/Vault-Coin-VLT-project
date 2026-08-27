# Security Policy

Vault Coin is currently a test-token implementation and has not been deployed.

## Reporting a vulnerability

Do not disclose exploitable findings in a public issue. Report them privately to
the repository owner through GitHub's private vulnerability reporting feature,
when enabled.

Include the affected commit, reproduction steps, expected impact, and a proposed
fix if available.

## Deployment safety

- Use a dedicated testnet deployer key.
- Never commit private keys, seed phrases, RPC credentials, or API keys.
- Verify `INITIAL_OWNER` and `INITIAL_RECIPIENT` before broadcasting.
- Test owner pause/unpause operations before considering any production version.
- Obtain an independent smart-contract review before a production deployment.
