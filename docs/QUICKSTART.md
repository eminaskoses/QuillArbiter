# Quick Start Guide

Get up and running with QuillArbiter in 5 minutes!

## Prerequisites

- Node.js v16+
- Git
- MetaMask or similar Web3 wallet

## Installation

```bash
# Clone the repository
git clone https://github.com/eminaskoses/QuillArbiter.git
cd QuillArbiter

# Install dependencies
npm install

# Compile contracts
npm run compile
```

## Run Tests

```bash
npm test
```

## Deploy Locally

```bash
# Terminal 1: Start local node
npm run node

# Terminal 2: Deploy contracts
npm run deploy
```

## Example Usage

### 1. File a Dispute

```javascript
const disputeFee = await disputeManager.disputeFee();
const tx = await disputeManager.fileDispute(
    defendantAddress,
    "QmHashOfDisputeDetails",
    escrowAddress,
    ethers.parseEther("1.0"),
    { value: disputeFee }
);
console.log("Dispute ID:", tx.wait().then(r => r.logs[0].args.disputeId));
```

### 2. Submit Evidence

```javascript
const evidenceHash = ethers.keccak256(evidenceData);
await evidenceVault.submitEvidence(
    disputeId,
    evidenceHash,
    "QmEncryptedEvidenceCID"
);
```

### 3. Become a Juror

```javascript
const minStake = await juryPool.minStakeAmount();
await juryPool.stake({ value: minStake });
```

### 4. Vote on a Dispute

```javascript
// Commit phase
const verdict = 1; // PlaintiffWins
const salt = ethers.randomBytes(32);
const voteHash = ethers.keccak256(
    ethers.AbiCoder.defaultAbiCoder().encode(
        ["uint256", "bytes32"],
        [verdict, salt]
    )
);
await votingCourt.commitVote(disputeId, voteHash);

// Wait for reveal phase...

// Reveal phase
await votingCourt.revealVote(disputeId, verdict, salt);
```

## Next Steps

- Read the [Architecture Documentation](ARCHITECTURE.md)
- Check the [API Reference](API.md)
- See [Deployment Guide](DEPLOYMENT.md) for mainnet
- Join our Discord community

## Troubleshooting

### Can't compile contracts
- Ensure Node.js v16+ is installed
- Delete `node_modules` and `package-lock.json`, then reinstall

### Tests failing
- Make sure no other Hardhat node is running
- Clear cache: `npx hardhat clean`

### Deployment issues
- Check you have enough ETH for gas
- Verify network configuration in `hardhat.config.js`

## Support

Need help? Open an issue on [GitHub](https://github.com/eminaskoses/QuillArbiter/issues)

