# QuillArbiter Deployment Guide

This guide provides step-by-step instructions for deploying QuillArbiter contracts to various networks.

## Prerequisites

- Node.js v16 or higher
- npm or yarn package manager
- Sufficient ETH for deployment gas fees
- Chainlink VRF subscription (for mainnet/testnet)

## Network Configuration

### Local Development (Hardhat Network)

```bash
# Start local node
npm run node

# In another terminal, deploy
npm run deploy
```

### Optimism Sepolia Testnet

1. **Get Test ETH**
   - Bridge Sepolia ETH to Optimism Sepolia using the official bridge
   - Use a faucet: https://faucet.quicknode.com/optimism/sepolia

2. **Configure Environment**
   ```bash
   cp .env.example .env
   ```

   Edit `.env`:
   ```
   OPTIMISM_SEPOLIA_RPC_URL=https://sepolia.optimism.io
   PRIVATE_KEY=your_private_key
   OPTIMISTIC_ETHERSCAN_API_KEY=your_api_key
   ```

3. **Setup Chainlink VRF**
   - Visit https://vrf.chain.link/
   - Create a subscription
   - Fund it with LINK tokens
   - Add your deployed JurySelection contract as a consumer

4. **Deploy**
   ```bash
   npx hardhat run scripts/deploy.js --network optimismSepolia
   ```

5. **Verify Contracts**
   ```bash
   node scripts/verify-contracts.js
   ```

### Optimism Mainnet

1. **Prepare Production Configuration**
   - Use a hardware wallet or secure key management
   - Ensure sufficient OP tokens for gas
   - Have LINK tokens for VRF subscription

2. **Update Environment**
   ```
   OPTIMISM_RPC_URL=https://mainnet.optimism.io
   PRIVATE_KEY=your_production_private_key
   VRF_COORDINATOR=0x... (mainnet coordinator)
   VRF_KEY_HASH=0x... (mainnet key hash)
   VRF_SUBSCRIPTION_ID=your_subscription_id
   ```

3. **Deploy**
   ```bash
   npx hardhat run scripts/deploy.js --network optimism
   ```

4. **Post-Deployment Steps**
   - Add JurySelection as VRF consumer
   - Transfer admin roles if needed
   - Configure fee amounts
   - Test with small amounts first

## Configuration Parameters

### DisputeManager
- `disputeFee`: Fee required to file a dispute (default: 0.01 ETH)
- `evidenceSubmissionPeriod`: Time window for evidence submission (default: 7 days)

### JuryPool
- `minStakeAmount`: Minimum stake to become a juror (default: 0.1 ETH)
- `minReputationScore`: Minimum reputation to be eligible (default: 50)
- `lockPeriod`: Lock period for staked tokens (default: 30 days)

### VotingCourt
- `commitPeriod`: Time for jurors to commit votes (default: 3 days)
- `revealPeriod`: Time for jurors to reveal votes (default: 2 days)

### AppealBoard
- `appealFee`: Fee required to file an appeal (default: 0.5 ETH)
- `appealPeriod`: Time window to file an appeal (default: 7 days)

## Role Management

After deployment, configure roles appropriately:

```javascript
// Example: Grant system roles
const SYSTEM_ROLE = ethers.keccak256(ethers.toUtf8Bytes("SYSTEM_ROLE"));

await disputeManager.grantRole(SYSTEM_ROLE, votingCourtAddress);
await disputeManager.grantRole(SYSTEM_ROLE, rulingExecutorAddress);
await disputeManager.grantRole(SYSTEM_ROLE, appealBoardAddress);

await juryPool.grantRole(SYSTEM_ROLE, jurySelectionAddress);
await juryPool.grantRole(SYSTEM_ROLE, votingCourtAddress);
```

## Security Checklist

- [ ] All private keys are securely stored
- [ ] Multi-sig is configured for admin operations
- [ ] Time locks are set for critical functions
- [ ] Contract addresses are saved and backed up
- [ ] VRF subscription is properly funded
- [ ] Initial testing completed on testnet
- [ ] All roles are correctly assigned
- [ ] Emergency pause mechanism is understood

## Monitoring

After deployment, monitor:

1. **Contract Events**
   - DisputeFiled
   - EvidenceSubmitted
   - JurorsSelected
   - VotingFinalized
   - RulingExecuted

2. **Financial Metrics**
   - Dispute fees collected
   - Juror stake amounts
   - Appeal fees collected
   - Escrow balances

3. **System Health**
   - VRF randomness requests
   - Voting participation rates
   - Average dispute resolution time
   - Juror reputation trends

## Troubleshooting

### VRF Not Working
- Verify subscription is funded with LINK
- Ensure contract is added as consumer
- Check callback gas limit is sufficient

### Transaction Failures
- Increase gas limit in hardhat.config.js
- Verify all dependencies are deployed
- Check role permissions are granted

### Verification Issues
- Ensure constructor arguments match deployment
- Use correct Etherscan API key
- Wait a few minutes after deployment

## Support

For deployment issues, please:
1. Check the GitHub Issues page
2. Review the test suite for examples
3. Join our Discord community

## Next Steps

After successful deployment:
1. Run integration tests
2. Set up monitoring dashboards
3. Prepare user documentation
4. Plan initial dispute scenarios
5. Engage with the community

