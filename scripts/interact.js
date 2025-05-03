const hre = require("hardhat");
const fs = require("fs");

/**
 * Example interaction script for QuillArbiter
 */
async function main() {
  console.log("QuillArbiter Interaction Script\n");

  const [owner, addr1, addr2] = await hre.ethers.getSigners();
  console.log("Using account:", owner.address);

  // Load deployment info
  if (!fs.existsSync("deployment-info.json")) {
    console.error("deployment-info.json not found. Please deploy first.");
    process.exit(1);
  }

  const deploymentInfo = JSON.parse(fs.readFileSync("deployment-info.json", "utf8"));
  const contracts = deploymentInfo.contracts;

  // Get contract instances
  const disputeManager = await hre.ethers.getContractAt(
    "DisputeManager",
    contracts.DisputeManager
  );
  const juryPool = await hre.ethers.getContractAt(
    "JuryPool",
    contracts.JuryPool
  );

  // Example 1: Check dispute fee
  const disputeFee = await disputeManager.disputeFee();
  console.log(`Current dispute fee: ${hre.ethers.formatEther(disputeFee)} ETH\n`);

  // Example 2: Check juror requirements
  const minStake = await juryPool.minStakeAmount();
  const minReputation = await juryPool.minReputationScore();
  console.log(`Juror Requirements:`);
  console.log(`  Min Stake: ${hre.ethers.formatEther(minStake)} ETH`);
  console.log(`  Min Reputation: ${minReputation}\n`);

  // Example 3: Get active jurors
  const activeJurors = await juryPool.getActiveJurors();
  console.log(`Active Jurors: ${activeJurors.length}\n`);

  // Example 4: Get total disputes
  const totalDisputes = await disputeManager.getTotalDisputes();
  console.log(`Total Disputes: ${totalDisputes}\n`);

  console.log("Interaction complete!");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

