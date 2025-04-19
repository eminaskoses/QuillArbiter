const hre = require("hardhat");
const fs = require("fs");

/**
 * Listen to contract events for monitoring
 */
async function main() {
  console.log("Starting event listener...");

  // Load deployment info
  if (!fs.existsSync("deployment-info.json")) {
    console.error("deployment-info.json not found.");
    process.exit(1);
  }

  const deploymentInfo = JSON.parse(fs.readFileSync("deployment-info.json", "utf8"));
  const contracts = deploymentInfo.contracts;

  // Get contract instances
  const disputeManager = await hre.ethers.getContractAt(
    "DisputeManager",
    contracts.DisputeManager
  );
  const evidenceVault = await hre.ethers.getContractAt(
    "EvidenceVault",
    contracts.EvidenceVault
  );
  const juryPool = await hre.ethers.getContractAt(
    "JuryPool",
    contracts.JuryPool
  );
  const votingCourt = await hre.ethers.getContractAt(
    "VotingCourt",
    contracts.VotingCourt
  );

  console.log("Listening for events...\n");

  // DisputeManager events
  disputeManager.on("DisputeFiled", (disputeId, plaintiff, defendant, metadataCID) => {
    console.log(`[DisputeManager] Dispute Filed:
      ID: ${disputeId}
      Plaintiff: ${plaintiff}
      Defendant: ${defendant}
      Metadata: ${metadataCID}
    `);
  });

  disputeManager.on("DisputeStatusChanged", (disputeId, oldStatus, newStatus) => {
    console.log(`[DisputeManager] Status Changed:
      ID: ${disputeId}
      Old: ${oldStatus}
      New: ${newStatus}
    `);
  });

  // EvidenceVault events
  evidenceVault.on("EvidenceSubmitted", (evidenceId, disputeId, submitter, evidenceHash) => {
    console.log(`[EvidenceVault] Evidence Submitted:
      Evidence ID: ${evidenceId}
      Dispute ID: ${disputeId}
      Submitter: ${submitter}
      Hash: ${evidenceHash}
    `);
  });

  // JuryPool events
  juryPool.on("JurorStaked", (juror, amount, totalStaked) => {
    console.log(`[JuryPool] Juror Staked:
      Juror: ${juror}
      Amount: ${hre.ethers.formatEther(amount)} ETH
      Total: ${hre.ethers.formatEther(totalStaked)} ETH
    `);
  });

  juryPool.on("ReputationUpdated", (juror, oldRep, newRep) => {
    console.log(`[JuryPool] Reputation Updated:
      Juror: ${juror}
      Old: ${oldRep}
      New: ${newRep}
    `);
  });

  // VotingCourt events
  votingCourt.on("VoteCommitted", (disputeId, juror, commitHash) => {
    console.log(`[VotingCourt] Vote Committed:
      Dispute ID: ${disputeId}
      Juror: ${juror}
      Hash: ${commitHash}
    `);
  });

  votingCourt.on("VoteRevealed", (disputeId, juror, verdict) => {
    console.log(`[VotingCourt] Vote Revealed:
      Dispute ID: ${disputeId}
      Juror: ${juror}
      Verdict: ${verdict}
    `);
  });

  votingCourt.on("VotingFinalized", (disputeId, finalVerdict, plaintiffVotes, defendantVotes) => {
    console.log(`[VotingCourt] Voting Finalized:
      Dispute ID: ${disputeId}
      Verdict: ${finalVerdict}
      Plaintiff Votes: ${plaintiffVotes}
      Defendant Votes: ${defendantVotes}
    `);
  });

  console.log("Event listener running. Press Ctrl+C to stop.\n");

  // Keep the process running
  await new Promise(() => {});
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});

