# Performance Guide

## Gas Optimization

### Contract-Level Optimizations

#### Storage Optimization
- Use `uint256` instead of smaller types when possible
- Pack struct variables to fit in 32-byte slots
- Use `mapping` instead of `array` for lookups
- Minimize storage writes

#### Function Optimization
- Mark functions as `view` or `pure` when applicable
- Use `calldata` for function parameters when possible
- Avoid loops with unbounded iterations
- Cache storage variables in memory

### Transaction Costs

#### Typical Gas Costs (Optimism)

| Operation | Gas Estimate | Cost (at 0.5 gwei) |
|-----------|--------------|-------------------|
| File Dispute | ~180,000 | $0.15 |
| Submit Evidence | ~80,000 | $0.07 |
| Stake as Juror | ~120,000 | $0.10 |
| Commit Vote | ~60,000 | $0.05 |
| Reveal Vote | ~70,000 | $0.06 |
| Execute Ruling | ~200,000 | $0.17 |
| File Appeal | ~150,000 | $0.13 |

## Performance Benchmarks

### Transaction Throughput
- Local Hardhat: 100-200 TPS
- Optimism Sepolia: 10-20 TPS
- Optimism Mainnet: 10-30 TPS

### Response Times
- Contract call (view): < 100ms
- Transaction confirmation: 1-2 seconds (Optimism)
- VRF callback: 3-5 blocks (~6-10 seconds)

## Optimization Strategies

### 1. Batch Operations
```javascript
// Instead of multiple transactions
for (const evidence of evidenceList) {
  await evidenceVault.submitEvidence(...);
}

// Submit in a single transaction with batch function
await evidenceVault.submitEvidenceBatch(evidenceList);
```

### 2. Event Filtering
```javascript
// Efficient event queries
const filter = contract.filters.DisputeFiled(null, plaintiff);
const events = await contract.queryFilter(filter, startBlock, endBlock);
```

### 3. Caching
```javascript
// Cache frequently accessed data
const cache = new Map();
async function getDispute(id) {
  if (!cache.has(id)) {
    cache.set(id, await disputeManager.getDisputeInfo(id));
  }
  return cache.get(id);
}
```

### 4. Pagination
```javascript
// Query large datasets in chunks
async function getAllDisputes(pageSize = 100) {
  const total = await disputeManager.getTotalDisputes();
  const disputes = [];
  
  for (let i = 0; i < total; i += pageSize) {
    const batch = await Promise.all(
      Array.from({length: Math.min(pageSize, total - i)}, (_, j) => 
        disputeManager.getDisputeInfo(i + j + 1)
      )
    );
    disputes.push(...batch);
  }
  
  return disputes;
}
```

## Monitoring

### Key Metrics
- Transaction success rate
- Average gas used per operation
- Block confirmation time
- Contract response time
- Event processing lag

### Tools
- Hardhat Gas Reporter
- Etherscan gas tracker
- Custom monitoring scripts
- The Graph for indexing

## Best Practices

1. **Test gas costs** before mainnet deployment
2. **Use events** for historical data instead of storage reads
3. **Implement pagination** for large data sets
4. **Cache static data** (fee amounts, addresses)
5. **Batch similar operations** when possible
6. **Monitor gas prices** and adjust timing
7. **Use off-chain computation** when feasible

## Scaling Considerations

### Current Limits
- Max jurors per dispute: 21
- Max evidence per dispute: Unlimited (pagination recommended)
- Max disputes: Unlimited
- Concurrent disputes: No limit

### Future Improvements
- Layer 3 integration for ultra-low costs
- Optimistic execution patterns
- State channels for high-frequency operations
- Sharded jury pools for parallelization

## Resources
- [Optimism Gas Tracker](https://optimism.io/gas-tracker)
- [Hardhat Gas Reporter](https://github.com/cgewecke/hardhat-gas-reporter)
- [EVM Gas Optimization Patterns](https://github.com/ewasm/design/blob/master/eth_interface.md)

