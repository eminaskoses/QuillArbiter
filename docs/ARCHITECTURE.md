# QuillArbiter Architecture

## System Overview

QuillArbiter is a modular, decentralized arbitration protocol built on Optimism. The system is designed with separation of concerns, allowing each contract to handle a specific aspect of the dispute resolution process.

## Core Components

### 1. DisputeManager

**Purpose:** Central registry and lifecycle manager for disputes

**Responsibilities:**
- Register new disputes with unique IDs
- Store dispute metadata references (IPFS CIDs)
- Track dispute status transitions
- Manage dispute fees
- Provide dispute information to other contracts

**Key State:**
- `mapping(disputeId => DisputeInfo)` - Stores all dispute data
- `mapping(address => disputeId[])` - User dispute history

**Access Control:**
- `DEFAULT_ADMIN_ROLE` - Can update fees and withdraw funds
- `SYSTEM_ROLE` - Can update dispute status
- `ARBITRATOR_ROLE` - Can close disputes

### 2. EvidenceVault

**Purpose:** Secure storage of evidence references with integrity verification

**Responsibilities:**
- Accept evidence submissions from dispute parties
- Store encrypted evidence CIDs (IPFS/Arweave)
- Maintain hash commitments for verification
- Link evidence to specific disputes

**Key Features:**
- Hash-based integrity verification
- Time-bound submission windows
- Encrypted off-chain storage references
- Optional ZK proof integration

**Access Control:**
- Only dispute parties can submit evidence
- Verifiers can validate evidence integrity

### 3. JuryPool

**Purpose:** Manage juror staking, reputation, and eligibility

**Responsibilities:**
- Accept and manage juror stakes
- Track juror reputation scores
- Handle slashing for misconduct
- Maintain list of active jurors
- Enforce minimum stake and lock periods

**Reputation System:**
- Initial reputation: 100
- Correct vote: +5% reputation
- Incorrect vote: -10% reputation
- Reputation cap: 1000

**Staking Mechanism:**
- Minimum stake: 0.1 ETH (configurable)
- Lock period: 30 days (configurable)
- Active status requires minimum stake + reputation

### 4. JurySelection

**Purpose:** Random, verifiable juror selection using Chainlink VRF

**Responsibilities:**
- Request randomness from Chainlink VRF
- Select jurors based on random values
- Ensure fair, unpredictable selection
- Prevent duplicate selections

**Selection Algorithm:**
```
1. Get list of active, eligible jurors
2. Request N random words from VRF
3. For each random word:
   - Calculate index: random % activeJurors.length
   - Select juror at index if eligible and not already selected
4. Store selected jurors for dispute
```

**Integration:**
- Uses Chainlink VRF V2
- Requires funded subscription
- Callback gas limit: 500,000

### 5. VotingCourt

**Purpose:** Conduct secure, anonymous voting with commit-reveal scheme

**Responsibilities:**
- Initialize voting sessions
- Accept commit hashes during commit phase
- Verify and accept reveals during reveal phase
- Tally votes and determine final verdict
- Prevent vote manipulation and coercion

**Voting Process:**
```
Phase 1: Commit (3 days)
- Juror computes: hash = keccak256(verdict, salt)
- Juror submits hash on-chain
- Votes remain hidden

Phase 2: Reveal (2 days)
- Juror submits (verdict, salt)
- Contract verifies: keccak256(verdict, salt) == commitHash
- Vote is counted if valid

Phase 3: Finalization
- Count plaintiff vs defendant votes
- Determine winner (or draw)
- Emit final verdict
```

**Verdict Types:**
- `PlaintiffWins` - Majority voted for plaintiff
- `DefendantWins` - Majority voted for defendant
- `Draw` - Equal votes or no clear majority

### 6. RulingExecutor

**Purpose:** Enforce final verdicts and manage settlements

**Responsibilities:**
- Execute rulings after voting finalization
- Interact with escrow contracts
- Distribute funds based on verdicts
- Apply penalties if configured
- Update juror reputations

**Execution Flow:**
```
1. Verify voting is finalized
2. Determine winner based on verdict
3. Create ruling record
4. Update dispute status
5. Release escrow to winner
6. Update juror reputations
7. Emit execution events
```

### 7. AppealBoard

**Purpose:** Handle appeals and re-evaluation requests

**Responsibilities:**
- Accept appeal filings with reasons
- Collect appeal fees
- Process appeals (accept/reject)
- Reset dispute status if accepted
- Manage appeal fee distribution

**Appeal Process:**
```
1. Losing party files appeal with fee
2. Arbitrator reviews appeal reason
3. If accepted:
   - Return appeal fee
   - Reset dispute to voting stage
   - Require new jury selection
4. If rejected:
   - Keep appeal fee
   - Ruling remains final
```

## Data Flow

### Complete Dispute Lifecycle

```
1. File Dispute (DisputeManager)
   ↓
2. Submit Evidence (EvidenceVault)
   ↓
3. Select Jurors (JurySelection + VRF)
   ↓
4. Initialize Voting (VotingCourt)
   ↓
5. Commit Phase (3 days)
   ↓
6. Reveal Phase (2 days)
   ↓
7. Finalize Voting (VotingCourt)
   ↓
8. Execute Ruling (RulingExecutor)
   ↓
9a. Close Dispute (DisputeManager)
   OR
9b. File Appeal (AppealBoard) → Return to step 4
```

## Security Architecture

### Anti-Collusion Measures

1. **VRF Random Selection**
   - Unpredictable juror selection
   - Cannot be influenced by parties

2. **Commit-Reveal Voting**
   - Votes hidden until reveal phase
   - Prevents vote following

3. **Time Locks**
   - Enforced periods for each phase
   - Prevents rushing to judgment

### Anti-Bribery Measures

1. **Hidden Votes**
   - Commitments hide vote direction
   - Cannot verify if bribe was followed

2. **Reputation at Stake**
   - Incorrect votes harm reputation
   - Long-term incentive for honesty

3. **Slashing Mechanism**
   - Malicious behavior results in stake loss
   - Economic disincentive for misconduct

### Evidence Integrity

1. **Hash Commitments**
   - Evidence cannot be tampered with
   - Verification against original hash

2. **Encrypted Storage**
   - Off-chain storage (IPFS/Arweave)
   - Controlled decryption for jurors

3. **ZK Proof Option**
   - Can prove evidence properties without revealing
   - Enhanced privacy when needed

## Contract Interaction Patterns

### Role-Based Access Control

All contracts use OpenZeppelin's AccessControl:

```
DEFAULT_ADMIN_ROLE
├─ Can grant/revoke roles
├─ Can update parameters
└─ Can withdraw fees

SYSTEM_ROLE
├─ Granted to other contracts
├─ Can update statuses
└─ Can trigger automated actions

ARBITRATOR_ROLE
├─ Can close disputes
├─ Can process appeals
└─ Can make governance decisions

VERIFIER_ROLE
├─ Can verify evidence
└─ Can validate submissions
```

### Cross-Contract Communication

Contracts communicate through:
1. **Interfaces** - Type-safe function calls
2. **Events** - Off-chain indexing and monitoring
3. **Direct Calls** - For immediate data needs
4. **Role Checks** - For authorization

## Scalability Considerations

### Optimism L2 Benefits

- **Low Gas Costs** - Enables frequent interactions
- **Fast Finality** - Quick confirmation times
- **EVM Compatibility** - Standard Solidity contracts
- **Security** - Inherits Ethereum mainnet security

### Gas Optimization

1. **Storage Patterns**
   - Use mappings over arrays when possible
   - Pack structs to minimize storage slots
   - Use events for historical data

2. **Computation**
   - Minimize loops in transactions
   - Move complex logic off-chain when possible
   - Use view functions for reads

3. **Batch Operations**
   - Support for batch evidence submission
   - Bulk role assignments
   - Multi-dispute queries

## Future Enhancements

### Planned Features

1. **Cross-Chain Disputes**
   - LayerZero integration
   - Multi-chain evidence support
   - Universal dispute registry

2. **Fully Private Voting**
   - Fully Homomorphic Encryption (FHE)
   - Zero-knowledge proofs for votes
   - No reveal phase needed

3. **DAO Integration**
   - Snapshot plugin
   - Safe module
   - Automated governance dispute resolution

4. **Reputation NFTs**
   - Tokenized juror reputation
   - Transferable credentials
   - Achievement system

5. **Specialized Courts**
   - Technical disputes
   - Financial disputes
   - NFT authenticity
   - DAO governance

## Performance Metrics

### Target Metrics

- Dispute filing: < 5 minutes
- Evidence submission: < 2 minutes per file
- Jury selection: < 10 minutes (VRF dependent)
- Voting session: 5 days (3 commit + 2 reveal)
- Ruling execution: < 5 minutes
- Appeal processing: < 1 day

### Cost Estimates (Optimism)

- File dispute: ~$0.10-0.50
- Submit evidence: ~$0.05-0.20
- Commit vote: ~$0.05-0.15
- Reveal vote: ~$0.05-0.15
- Execute ruling: ~$0.20-0.80

## Testing Strategy

### Unit Tests
- Individual contract functions
- Edge cases and error conditions
- Access control verification

### Integration Tests
- Multi-contract interactions
- Complete dispute lifecycle
- Role-based workflows

### Scenario Tests
- Real-world dispute simulations
- Attack vector testing
- Gas consumption analysis

## Monitoring and Maintenance

### Key Metrics to Monitor

1. **System Health**
   - Active juror count
   - Average stake amount
   - VRF request success rate

2. **Usage Statistics**
   - Disputes filed per day
   - Evidence submissions
   - Voting participation rate

3. **Financial Health**
   - Total value locked
   - Fee collection
   - Escrow volumes

4. **Performance**
   - Transaction success rates
   - Average resolution time
   - Gas costs

### Upgrade Strategy

- Use proxy patterns for upgradeability
- Implement timelock for governance actions
- Maintain backwards compatibility
- Document all changes thoroughly

