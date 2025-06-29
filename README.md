# SquadSafe Contracts (Foundry)

## Overview

This Foundry project contains the smart contracts for SquadSafe, the onchain group vault and social finance agent built for the Base Batch Messaging Buildathon. All contracts are designed for security, composability, and seamless integration with XMTP agents and the Base L2 network.

## Key Features

- **Group Vault:** Multi-sig, programmable vault for group funds (ETH, USDC, ERC-20)
- **Proposal & Voting:** Onchain governance for group payments, investments, and actions
- **Execution:** Secure, auditable payment and DeFi actions
- **Security:** Built with OpenZeppelin libraries, multi-sig, and modern best practices
- **Compliance:** Designed for OFAC screening and robust error handling

## Modern Best Practices

- Built with [Foundry](https://getfoundry.sh/) for fast, reliable Solidity development
- Uses [OpenZeppelin](https://openzeppelin.com/contracts/) for secure, audited contract modules
- Modular, upgradeable architecture (proxy pattern ready)
- Comprehensive tests in `/test` using forge-std
- Fuzzing and invariant testing for security
- Gas optimization and Base L2 compatibility

## Getting Started

### 1. Install Foundry

See: https://getfoundry.sh/introduction/installation

```
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

### 2. Build Contracts

```
forge build
```

### 3. Run Tests

```
forge test
```

### 4. Deploy

Use `forge script` or your preferred deployment tool. (Deployment scripts will be added in `/script`.)

### 5. Lint & Format

```
forge fmt
```

## Directory Structure

- `src/` - Main contract sources
- `test/` - Test contracts
- `script/` - Deployment and management scripts
- `lib/` - External libraries (e.g., OpenZeppelin, forge-std)

## Security

- All contracts use OpenZeppelin modules for ERC-20, multi-sig, and access control
- Re-entrancy protection, input validation, and event logging
- Designed for auditability and upgradeability

## License

MIT

---

**This project is the onchain foundation for SquadSafe, optimized for security, composability, and a winning buildathon submission.**

## Deploying the Test Token (TTK)

A simple ERC-20 token (`TestToken`) is provided for testing and demo purposes. You can deploy it and mint tokens to yourself and/or the SquadSafeVault.

### Deploy TestToken and Mint to Deployer

```
forge script script/DeployTestToken.s.sol --rpc-url <RPC_URL> --private-key <PRIVATE_KEY> --broadcast
```

### Optionally Mint to the Vault

Set the `VAULT_ADDRESS` environment variable to mint tokens directly to your deployed vault:

```
export VAULT_ADDRESS=<YOUR_VAULT_ADDRESS>
forge script script/DeployTestToken.s.sol --rpc-url <RPC_URL> --private-key <PRIVATE_KEY> --broadcast
```

- The deployer receives 1,000,000 TTK by default.
- The vault (if specified) receives 100,000 TTK.

> **Security Note:** The test token is for demo/testing only. Minting is restricted to the deployer.
