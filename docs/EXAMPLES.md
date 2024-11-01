# Code Examples

## Basic Usage Examples

### Example 1: Filing a Dispute

```javascript
const { ethers } = require("hardhat");

async function fileDispute() {
  const [plaintiff] = await ethers.getSigners();
  
  const disputeManager = await ethers.getContractAt(
    "DisputeManager",
    "0x..." // deployed address
  );

  const disputeFee = await disputeManager.disputeFee();
  
  const tx = await disputeManager.fileDispute(
    "0xDefendantAddress",
    "QmIPFSHashOfDisputeDetails",
    "0xEscrowContractAddress",
    ethers.parseEther("1.0"),
    { value: disputeFee }
  );

  const receipt = await tx.wait();
  console.log("Dispute filed successfully");
}
```

### Example 2: Submitting Evidence

```javascript
async function submitEvidence(disputeId) {
  const evidenceVault = await ethers.getContractAt(
    "EvidenceVault",
    "0x..."
  );

  // Prepare evidence
  const evidenceData = "My evidence document";
  const evidenceHash = ethers.keccak256(
    ethers.toUtf8Bytes(evidenceData)
  );

  // Upload to IPFS and get CID
  const encryptedCID = "QmEncryptedEvidenceCID";

  const tx = await evidenceVault.submitEvidence(
    disputeId,
    evidenceHash,
    encryptedCID
  );

  await tx.wait();
  console.log("Evidence submitted");
}
```

### Example 3: Staking as a Juror

```javascript
async function stakeAsJuror() {
  const juryPool = await ethers.getContractAt(
    "JuryPool",
    "0x..."
  );

  const minStake = await juryPool.minStakeAmount();
  
  const tx = await juryPool.stake({
    value: minStake
  });

  await tx.wait();
  console.log("Successfully staked as juror");
}
```

### Example 4: Commit-Reveal Voting

```javascript
async function commitVote(disputeId, verdict) {
  const votingCourt = await ethers.getContractAt(
    "VotingCourt",
    "0x..."
  );

  // Generate random salt
  const salt = ethers.randomBytes(32);
  
  // Create commit hash
  const voteHash = ethers.keccak256(
    ethers.AbiCoder.defaultAbiCoder().encode(
      ["uint256", "bytes32"],
      [verdict, salt]
    )
  );

  // Commit vote
  const commitTx = await votingCourt.commitVote(disputeId, voteHash);
  await commitTx.wait();
  
  console.log("Vote committed");
  console.log("Save your salt:", ethers.hexlify(salt));

  // Later, during reveal period...
  const revealTx = await votingCourt.revealVote(
    disputeId,
    verdict,
    salt
  );
  await revealTx.wait();
  
  console.log("Vote revealed");
}
```

### Example 5: Listening to Events

```javascript
async function listenToDisputes() {
  const disputeManager = await ethers.getContractAt(
    "DisputeManager",
    "0x..."
  );

  // Listen to DisputeFiled events
  disputeManager.on("DisputeFiled", (disputeId, plaintiff, defendant, metadataCID) => {
    console.log(`New dispute filed:`);
    console.log(`  ID: ${disputeId}`);
    console.log(`  Plaintiff: ${plaintiff}`);
    console.log(`  Defendant: ${defendant}`);
    console.log(`  Metadata: ${metadataCID}`);
  });

  console.log("Listening for disputes...");
}
```

### Example 6: Querying Dispute Status

```javascript
async function checkDisputeStatus(disputeId) {
  const disputeManager = await ethers.getContractAt(
    "DisputeManager",
    "0x..."
  );

  const dispute = await disputeManager.getDisputeInfo(disputeId);

  console.log("Dispute Information:");
  console.log(`  Status: ${dispute.status}`);
  console.log(`  Plaintiff: ${dispute.plaintiff}`);
  console.log(`  Defendant: ${dispute.defendant}`);
  console.log(`  Escrow: ${ethers.formatEther(dispute.escrowAmount)} ETH`);
  console.log(`  Filed At: ${new Date(Number(dispute.filedAt) * 1000)}`);
}
```

### Example 7: Filing an Appeal

```javascript
async function fileAppeal(disputeId) {
  const appealBoard = await ethers.getContractAt(
    "AppealBoard",
    "0x..."
  );

  const appealFee = await appealBoard.appealFee();
  const reason = "The ruling was based on insufficient evidence";

  const tx = await appealBoard.fileAppeal(
    disputeId,
    reason,
    { value: appealFee }
  );

  const receipt = await tx.wait();
  console.log("Appeal filed successfully");
}
```

### Example 8: Batch Operations

```javascript
async function batchSubmitEvidence(disputeId, evidenceList) {
  const evidenceVault = await ethers.getContractAt(
    "EvidenceVault",
    "0x..."
  );

  for (const evidence of evidenceList) {
    const hash = ethers.keccak256(ethers.toUtf8Bytes(evidence.data));
    
    const tx = await evidenceVault.submitEvidence(
      disputeId,
      hash,
      evidence.cid
    );
    
    await tx.wait();
    console.log(`Evidence ${evidence.cid} submitted`);
  }
}
```

## Advanced Examples

### Custom Error Handling

```javascript
async function safeFileDispute(defendantAddress, metadataCID) {
  try {
    const disputeManager = await ethers.getContractAt(
      "DisputeManager",
      "0x..."
    );

    const disputeFee = await disputeManager.disputeFee();
    
    const tx = await disputeManager.fileDispute(
      defendantAddress,
      metadataCID,
      ethers.ZeroAddress,
      0,
      { value: disputeFee }
    );

    const receipt = await tx.wait();
    return receipt;
    
  } catch (error) {
    if (error.message.includes("Insufficient dispute fee")) {
      console.error("Not enough ETH sent for dispute fee");
    } else if (error.message.includes("Cannot dispute with yourself")) {
      console.error("Plaintiff and defendant cannot be the same");
    } else {
      console.error("Unknown error:", error.message);
    }
    throw error;
  }
}
```

### Gas Estimation

```javascript
async function estimateDisputeCost() {
  const disputeManager = await ethers.getContractAt(
    "DisputeManager",
    "0x..."
  );

  const disputeFee = await disputeManager.disputeFee();
  
  const gasEstimate = await disputeManager.fileDispute.estimateGas(
    "0xDefendantAddress",
    "QmMetadata",
    ethers.ZeroAddress,
    0,
    { value: disputeFee }
  );

  const gasPrice = await ethers.provider.getFeeData();
  const gasCost = gasEstimate * gasPrice.gasPrice;

  console.log(`Gas estimate: ${gasEstimate}`);
  console.log(`Gas cost: ${ethers.formatEther(gasCost)} ETH`);
  console.log(`Dispute fee: ${ethers.formatEther(disputeFee)} ETH`);
  console.log(`Total cost: ${ethers.formatEther(gasCost + disputeFee)} ETH`);
}
```

## Testing Examples

### Unit Test Example

```javascript
describe("DisputeManager", function () {
  it("Should file a dispute correctly", async function () {
    const [owner, plaintiff, defendant] = await ethers.getSigners();
    
    const DisputeManager = await ethers.getContractFactory("DisputeManager");
    const disputeManager = await DisputeManager.deploy(ethers.parseEther("0.01"));
    
    await expect(
      disputeManager.connect(plaintiff).fileDispute(
        defendant.address,
        "QmTest",
        ethers.ZeroAddress,
        0,
        { value: ethers.parseEther("0.01") }
      )
    ).to.emit(disputeManager, "DisputeFiled");
  });
});
```

For more examples, see the [test directory](../test/).

