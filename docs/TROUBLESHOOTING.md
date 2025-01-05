# Troubleshooting Guide

## Common Issues and Solutions

### Installation Issues

#### Problem: `npm install` fails
**Solution:**
```bash
# Clear cache and reinstall
rm -rf node_modules package-lock.json
npm cache clean --force
npm install
```

#### Problem: Node version incompatibility
**Solution:**
```bash
# Use nvm to switch to correct version
nvm install 18
nvm use 18
```

### Compilation Issues

#### Problem: Solidity compiler errors
**Solution:**
- Ensure Solidity version is ^0.8.20
- Run `npx hardhat clean` then recompile
- Check for syntax errors in contracts

#### Problem: Out of memory during compilation
**Solution:**
```bash
# Increase Node memory
export NODE_OPTIONS="--max-old-space-size=4096"
npm run compile
```

### Testing Issues

#### Problem: Tests timeout
**Solution:**
```javascript
// Increase timeout in test
this.timeout(60000); // 60 seconds
```

#### Problem: VRF tests fail
**Solution:**
- Use MockVRFCoordinator for testing
- Ensure callback gas limit is sufficient
- Check VRF subscription is funded

### Deployment Issues

#### Problem: Insufficient funds for deployment
**Solution:**
- Ensure wallet has enough ETH
- Check gas price and adjust in hardhat.config.js
- Use testnet first to estimate costs

#### Problem: Transaction reverted during deployment
**Solution:**
- Check constructor parameters
- Verify network configuration
- Ensure no conflicting deployments

#### Problem: Contract verification fails
**Solution:**
```bash
# Verify with correct parameters
npx hardhat verify --network optimismSepolia DEPLOYED_ADDRESS "constructor_arg1" "constructor_arg2"
```

### Runtime Issues

#### Problem: "Insufficient dispute fee" error
**Solution:**
```javascript
const disputeFee = await disputeManager.disputeFee();
// Ensure msg.value >= disputeFee
await disputeManager.fileDispute(..., { value: disputeFee });
```

#### Problem: "Not a selected juror" error
**Solution:**
- Check if address is in selected jurors list
- Verify jury selection completed
- Ensure juror is eligible (staked and reputation sufficient)

#### Problem: "Commit period not ended" error
**Solution:**
- Wait for commit period to end
- Check current block timestamp
- Use time helpers in tests

#### Problem: "Invalid reveal" error
**Solution:**
- Ensure salt matches commit
- Verify verdict matches commit
- Check hash calculation is correct

### Transaction Issues

#### Problem: Transaction stuck/pending
**Solution:**
```bash
# Check transaction status
npx hardhat run scripts/check-tx.js --network optimismSepolia

# Speed up transaction (increase gas price)
# Or cancel transaction (send 0 ETH to self with same nonce)
```

#### Problem: Gas estimation fails
**Solution:**
- Check contract state allows operation
- Verify all requirements are met
- Try static call to identify revert reason

### Role/Permission Issues

#### Problem: "AccessControl: account is missing role"
**Solution:**
```bash
# Grant necessary roles
npx hardhat run scripts/grant-roles.js
```

#### Problem: Cannot update contract parameters
**Solution:**
- Verify you have DEFAULT_ADMIN_ROLE
- Check transaction is from admin account
- Use correct role for operation

### Event Listening Issues

#### Problem: Events not received
**Solution:**
- Ensure contract address is correct
- Verify ABI matches deployed contract
- Check WebSocket connection is stable
- Use polling if WebSocket unavailable

#### Problem: Historical events not found
**Solution:**
```javascript
// Query events from specific block
const events = await contract.queryFilter(
  contract.filters.DisputeFiled(),
  startBlock,
  endBlock
);
```

### Network Issues

#### Problem: RPC errors
**Solution:**
- Check RPC URL in .env
- Try alternative RPC providers
- Implement retry logic
- Use rate limiting

#### Problem: Network congestion
**Solution:**
- Increase gas price
- Wait for off-peak hours
- Use L2 (Optimism) for lower costs

### Data Issues

#### Problem: IPFS content not accessible
**Solution:**
- Use pinning services
- Try multiple gateways
- Implement fallback to Arweave
- Check CID is valid

#### Problem: State inconsistencies
**Solution:**
- Clear local blockchain state
- Redeploy contracts
- Verify on-chain state matches expected
- Check for race conditions

### Integration Issues

#### Problem: Frontend can't connect to contracts
**Solution:**
```javascript
// Verify contract addresses
const addresses = require('./deployment-info.json');

// Check network matches
const network = await provider.getNetwork();
console.log('Connected to:', network.name);
```

#### Problem: MetaMask transaction fails
**Solution:**
- Check MetaMask is on correct network
- Ensure sufficient ETH for gas
- Clear MetaMask activity tab
- Reset MetaMask account if needed

## Getting Help

If you encounter issues not covered here:

1. Check [GitHub Issues](https://github.com/eminaskoses/QuillArbiter/issues)
2. Search [GitHub Discussions](https://github.com/eminaskoses/QuillArbiter/discussions)
3. Review [Documentation](README.md)
4. Ask in Discord community

## Reporting Bugs

When reporting issues, include:
- Error messages (full stack trace)
- Steps to reproduce
- Environment details (OS, Node version, network)
- Relevant code snippets
- Expected vs actual behavior

## Debug Mode

Enable debug logging:
```bash
DEBUG=* npm test
DEBUG=hardhat:* npm run deploy
```

