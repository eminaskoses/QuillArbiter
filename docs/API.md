# QuillArbiter API Reference

## DisputeManager

### Functions

#### fileDispute
```solidity
function fileDispute(
    address defendant,
    string memory metadataCID,
    address escrowContract,
    uint256 escrowAmount
) external payable returns (uint256)
```

Files a new dispute against a defendant.

**Parameters:**
- `defendant`: Address of the party being disputed against
- `metadataCID`: IPFS CID containing dispute details and documentation
- `escrowContract`: Address of escrow contract holding disputed funds
- `escrowAmount`: Amount locked in escrow

**Requirements:**
- `msg.value >= disputeFee`
- `defendant != address(0)`
- `defendant != msg.sender`

**Returns:** Unique dispute ID

**Events:** `DisputeFiled`

#### updateDisputeStatus
```solidity
function updateDisputeStatus(
    uint256 disputeId,
    DisputeStatus newStatus
) external
```

Updates the status of a dispute. Only callable by system contracts.

**Access:** `SYSTEM_ROLE`

#### closeDispute
```solidity
function closeDispute(uint256 disputeId) external
```

Closes a dispute. Can be called by arbitrators or dispute parties.

**Access:** `ARBITRATOR_ROLE` or dispute parties

#### getDisputeInfo
```solidity
function getDisputeInfo(uint256 disputeId) 
    external view returns (DisputeInfo memory)
```

Retrieves complete information about a dispute.

**Returns:** DisputeInfo struct

---

## EvidenceVault

### Functions

#### submitEvidence
```solidity
function submitEvidence(
    uint256 disputeId,
    bytes32 evidenceHash,
    string memory encryptedCID
) external returns (uint256)
```

Submits evidence for a dispute.

**Parameters:**
- `disputeId`: ID of the related dispute
- `evidenceHash`: Keccak256 hash of the evidence for integrity
- `encryptedCID`: IPFS/Arweave CID of encrypted evidence file

**Requirements:**
- Caller must be plaintiff or defendant
- Dispute must be in submission phase
- Within submission deadline

**Returns:** Evidence ID

**Events:** `EvidenceSubmitted`

#### verifyEvidence
```solidity
function verifyEvidence(
    uint256 evidenceId,
    bytes32 providedHash
) external returns (bool)
```

Verifies evidence integrity by comparing hashes.

**Access:** `VERIFIER_ROLE`

**Returns:** True if hashes match

---

## JuryPool

### Functions

#### stake
```solidity
function stake() external payable
```

Stakes ETH to become a juror.

**Requirements:**
- `msg.value >= minStakeAmount`

**Events:** `JurorStaked`

#### withdraw
```solidity
function withdraw(uint256 amount) external
```

Withdraws staked tokens after lock period.

**Requirements:**
- Sufficient staked amount
- Lock period has passed

**Events:** `JurorWithdrawn`

#### slash
```solidity
function slash(address juror, uint256 amount) external
```

Slashes a juror's stake for misconduct.

**Access:** `SYSTEM_ROLE`

**Events:** `JurorSlashed`

#### updateReputation
```solidity
function updateReputation(address juror, bool correctVote) external
```

Updates juror reputation based on voting accuracy.

**Access:** `SYSTEM_ROLE`

**Events:** `ReputationUpdated`

#### isEligibleJuror
```solidity
function isEligibleJuror(address juror) 
    external view returns (bool)
```

Checks if an address is eligible for jury selection.

**Requirements for eligibility:**
- Active status
- Stake >= minStakeAmount
- Reputation >= minReputationScore

---

## JurySelection

### Functions

#### selectJurors
```solidity
function selectJurors(
    uint256 disputeId,
    uint256 jurorCount
) external returns (uint256)
```

Initiates random juror selection via Chainlink VRF.

**Access:** `SYSTEM_ROLE`

**Parameters:**
- `disputeId`: Dispute requiring jury
- `jurorCount`: Number of jurors to select

**Returns:** VRF request ID

**Events:** `SelectionRequested`, `JurorsSelected` (after callback)

#### getSelectedJurors
```solidity
function getSelectedJurors(uint256 disputeId) 
    external view returns (address[] memory)
```

Returns array of selected jurors for a dispute.

---

## VotingCourt

### Functions

#### initializeVoting
```solidity
function initializeVoting(uint256 disputeId) external
```

Initializes a voting session for a dispute.

**Access:** `SYSTEM_ROLE`

#### commitVote
```solidity
function commitVote(uint256 disputeId, bytes32 voteHash) external
```

Commits a vote hash during commit phase.

**Parameters:**
- `disputeId`: Dispute being voted on
- `voteHash`: `keccak256(abi.encodePacked(uint256(verdict), salt))`

**Requirements:**
- Caller is selected juror
- Within commit period
- Not already committed

**Events:** `VoteCommitted`

#### revealVote
```solidity
function revealVote(
    uint256 disputeId,
    Verdict verdict,
    bytes32 salt
) external
```

Reveals a committed vote during reveal phase.

**Parameters:**
- `disputeId`: Dispute being voted on
- `verdict`: The actual vote (1=PlaintiffWins, 2=DefendantWins)
- `salt`: Random bytes32 used in commit

**Requirements:**
- Commit period ended
- Within reveal period
- Hash matches commit

**Events:** `VoteRevealed`

#### finalizeVoting
```solidity
function finalizeVoting(uint256 disputeId) 
    external returns (Verdict)
```

Finalizes voting and determines outcome.

**Requirements:**
- Reveal period ended
- Not already finalized

**Returns:** Final verdict

**Events:** `VotingFinalized`

---

## RulingExecutor

### Functions

#### executeRuling
```solidity
function executeRuling(uint256 disputeId) external
```

Executes the final ruling based on voting outcome.

**Requirements:**
- Voting is finalized
- Not already executed

**Events:** `RulingExecuted`, `EscrowReleased`

#### getRuling
```solidity
function getRuling(uint256 disputeId) 
    external view returns (Ruling memory)
```

Retrieves ruling details for a dispute.

---

## AppealBoard

### Functions

#### fileAppeal
```solidity
function fileAppeal(
    uint256 disputeId,
    string memory reason
) external payable returns (uint256)
```

Files an appeal for a dispute ruling.

**Parameters:**
- `disputeId`: Dispute to appeal
- `reason`: Written justification for appeal

**Requirements:**
- `msg.value >= appealFee`
- Caller is plaintiff or defendant
- Dispute has been executed
- No active appeal exists

**Returns:** Appeal ID

**Events:** `AppealFiled`

#### processAppeal
```solidity
function processAppeal(uint256 appealId, bool accept) external
```

Processes an appeal decision.

**Access:** `ARBITRATOR_ROLE`

**Parameters:**
- `appealId`: Appeal to process
- `accept`: Whether to accept or reject appeal

**Events:** `AppealProcessed`

---

## Events Reference

### DisputeManager Events

```solidity
event DisputeFiled(
    uint256 indexed disputeId,
    address indexed plaintiff,
    address indexed defendant,
    string metadataCID,
    uint256 timestamp
);

event DisputeStatusChanged(
    uint256 indexed disputeId,
    DisputeStatus oldStatus,
    DisputeStatus newStatus
);

event DisputeClosed(
    uint256 indexed disputeId,
    uint256 timestamp
);
```

### EvidenceVault Events

```solidity
event EvidenceSubmitted(
    uint256 indexed evidenceId,
    uint256 indexed disputeId,
    address indexed submitter,
    bytes32 evidenceHash,
    uint256 timestamp
);

event EvidenceVerified(
    uint256 indexed evidenceId,
    bool verified
);
```

### JuryPool Events

```solidity
event JurorStaked(
    address indexed juror,
    uint256 amount,
    uint256 totalStaked,
    uint256 timestamp
);

event JurorWithdrawn(
    address indexed juror,
    uint256 amount,
    uint256 remainingStake,
    uint256 timestamp
);

event JurorSlashed(
    address indexed juror,
    uint256 amount,
    uint256 remainingStake,
    uint256 timestamp
);

event ReputationUpdated(
    address indexed juror,
    uint256 oldReputation,
    uint256 newReputation
);
```

### VotingCourt Events

```solidity
event VoteCommitted(
    uint256 indexed disputeId,
    address indexed juror,
    bytes32 commitHash,
    uint256 timestamp
);

event VoteRevealed(
    uint256 indexed disputeId,
    address indexed juror,
    Verdict verdict,
    uint256 timestamp
);

event VotingFinalized(
    uint256 indexed disputeId,
    Verdict finalVerdict,
    uint256 plaintiffVotes,
    uint256 defendantVotes,
    uint256 timestamp
);
```

---

## Error Codes

Common revert messages:

- `"Insufficient dispute fee"` - Not enough ETH sent
- `"Invalid defendant address"` - Defendant is zero address
- `"Cannot dispute with yourself"` - Plaintiff and defendant are same
- `"Dispute does not exist"` - Invalid dispute ID
- `"Not authorized"` - Caller lacks required role
- `"Already committed"` - Vote already committed
- `"Already revealed"` - Vote already revealed
- `"Invalid reveal"` - Reveal data doesn't match commit
- `"Commit period not ended"` - Trying to reveal too early
- `"Reveal period ended"` - Trying to reveal too late

---

## Usage Examples

### Filing a Dispute

```javascript
const disputeFee = await disputeManager.disputeFee();
const tx = await disputeManager.fileDispute(
    defendantAddress,
    "QmHashOfDisputeDetails",
    escrowContractAddress,
    ethers.parseEther("1.0"),
    { value: disputeFee }
);
```

### Submitting Evidence

```javascript
const evidenceHash = ethers.keccak256(evidenceData);
await evidenceVault.submitEvidence(
    disputeId,
    evidenceHash,
    "QmHashOfEncryptedEvidence"
);
```

### Committing a Vote

```javascript
const verdict = 1; // PlaintiffWins
const salt = ethers.randomBytes(32);
const voteHash = ethers.keccak256(
    ethers.AbiCoder.defaultAbiCoder().encode(
        ["uint256", "bytes32"],
        [verdict, salt]
    )
);

await votingCourt.commitVote(disputeId, voteHash);

// Later, during reveal phase:
await votingCourt.revealVote(disputeId, verdict, salt);
```

