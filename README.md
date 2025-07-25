# QuillArbiter

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Solidity](https://img.shields.io/badge/Solidity-^0.8.20-blue)](https://soliditylang.org/)
[![Hardhat](https://img.shields.io/badge/Built%20with-Hardhat-orange)](https://hardhat.org/)

Decentralized Arbitration & Evidence Vault Protocol

## Overview

QuillArbiter is a decentralized arbitration and evidence-verification protocol designed to resolve on-chain and off-chain disputes with verifiable proofs, encrypted evidence storage, jury voting, and enforceable smart contract rulings. Unlike traditional arbitration, rulings in QuillArbiter are trustless, censorship-resistant, and automatically executable.

**Target Chain:** Optimism (EVM) + IPFS/Arweave evidence layer

## Use Cases

- DAO governance disputes
- NFT copyright and ownership disputes
- Service delivery and escrow conflicts
- B2B settlement and milestone enforcement

## Core Features

- **Encrypted Evidence Vault** - Secure storage with controlled decryption and hash commitments
- **Jury-Based Arbitration** - Staking, random selection via Chainlink VRF, and reputation system
- **ZK-Enabled Integrity** - Optional zero-knowledge proofs for evidence verification
- **Automated Execution** - Smart contract enforcement of rulings (escrow release, penalties, refunds)
- **Appeal Mechanism** - Second-layer arbitration with higher stake thresholds
- **Commit-Reveal Voting** - Time-locked voting system to prevent coercion and collusion

## Architecture

The protocol consists of modular smart contracts:

- **DisputeManager** - Creates and manages dispute lifecycle
- **EvidenceVault** - Stores encrypted evidence references with hash commitments
- **JuryPool** - Manages juror staking and reputation
- **JurySelection** - VRF-based random jury selection
- **VotingCourt** - Commit-reveal voting mechanism
- **RulingExecutor** - Enforces final rulings on-chain
- **AppealBoard** - Handles appeal process

## Technology Stack

- Solidity ^0.8.20
- Hardhat Development Environment
- Optimism L2 Network
- Chainlink VRF for randomness
- OpenZeppelin Contracts
- IPFS/Arweave for evidence storage

## Installation

```bash
npm install
```

## Configuration

Copy the example environment file and configure it:

```bash
cp .env.example .env
```

Edit `.env` with your configuration:
- Network RPC URLs
- Private keys
- Chainlink VRF parameters
- Etherscan API keys

## Compilation

```bash
npm run compile
```

## Testing

Run the complete test suite:

```bash
# Run all tests
npm run test

# Run with coverage
npm run test:coverage

# Run with gas reporting
npm run test:gas
```

## Deployment

Deploy to local Hardhat network:

```bash
npm run node
npm run deploy
```

Deploy to Optimism Sepolia testnet:

```bash
npx hardhat run scripts/deploy.js --network optimismSepolia
```

## Contract Addresses

After deployment, contract addresses will be saved to `deployment-info.json`.

## Security

- Anti-collusion: Commit-reveal + VRF random selection
- Anti-bribery: Hidden votes + delayed reveal
- Evidence integrity: Hash commitment + optional ZK proofs
- Finality guarantee: Time-locked ruling enforcement
- Governance: Role-based access control with OpenZeppelin

## Roadmap

See [ROADMAP.md](docs/ROADMAP.md) for detailed timeline.

- [ ] Cross-chain dispute resolution via LayerZero
- [ ] Fully private juror voting with FHE
- [ ] DAO plugin for Snapshot/Safe integration
- [ ] Reputation tokenization for juror performance
- [ ] Mobile-friendly juror dashboard

For more information, see our [documentation](docs/).

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License - see LICENSE file for details

## Community

- GitHub: [QuillArbiter Repository](https://github.com/eminaskoses/QuillArbiter)
- Issues: [Report bugs or request features](https://github.com/eminaskoses/QuillArbiter/issues)
- Discussions: [Join the conversation](https://github.com/eminaskoses/QuillArbiter/discussions)

## Contact

For questions and support, please open an issue on GitHub.

