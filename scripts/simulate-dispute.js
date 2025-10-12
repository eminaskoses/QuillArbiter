const hre = require("hardhat");

/**
 * Simulate a complete dispute lifecycle for testing
 */
async function main() {
  console.log("Starting dispute simulation...\n");

  const [owner, plaintiff, defendant, juror1, juror2, juror3] = await hre.ethers.getSigners();

  // Deploy contracts (simplified - in reality use deployed addresses)
  console.log("Deploying contracts...");
  const disputeFee = hre.ethers.parseEther("0.01");
  
  const DisputeManager = await hre.ethers.getContractFactory("DisputeManager");
  const disputeManager = await DisputeManager.deploy(disputeFee);
  await disputeManager.waitForDeployment();
  console.log("DisputeManager deployed");

  const JuryPool = await hre.ethers.getContractFactory("JuryPool");
  const juryPool = await JuryPool.deploy();
  await juryPool.waitForDeployment();
  console.log("JuryPool deployed\n");

  // Step 1: Jurors stake
  console.log("Step 1: Jurors staking...");
  const minStake = await juryPool.minStakeAmount();
  
  await juryPool.connect(juror1).stake({ value: minStake });
  console.log(`Juror 1 staked ${hre.ethers.formatEther(minStake)} ETH`);
  
  await juryPool.connect(juror2).stake({ value: minStake });
  console.log(`Juror 2 staked ${hre.ethers.formatEther(minStake)} ETH`);
  
  await juryPool.connect(juror3).stake({ value: minStake });
  console.log(`Juror 3 staked ${hre.ethers.formatEther(minStake)} ETH\n`);

  // Step 2: File dispute
  console.log("Step 2: Filing dispute...");
  const tx = await disputeManager.connect(plaintiff).fileDispute(
    defendant.address,
    "QmSimulatedDisputeMetadata123",
    hre.ethers.ZeroAddress,
    hre.ethers.parseEther("1.0"),
    { value: disputeFee }
  );
  await tx.wait();
  console.log("Dispute filed with ID: 1\n");

  // Step 3: Get dispute info
  console.log("Step 3: Checking dispute status...");
  const dispute = await disputeManager.getDisputeInfo(1);
  console.log(`Plaintiff: ${dispute.plaintiff}`);
  console.log(`Defendant: ${dispute.defendant}`);
  console.log(`Status: ${dispute.status}`);
  console.log(`Escrow Amount: ${hre.ethers.formatEther(dispute.escrowAmount)} ETH\n`);

  // Step 4: Check juror stats
  console.log("Step 4: Checking juror statistics...");
  const activeJurors = await juryPool.getActiveJurors();
  console.log(`Active jurors: ${activeJurors.length}`);
  
  const juror1Data = await juryPool.getJuror(juror1.address);
  console.log(`Juror 1 reputation: ${juror1Data.reputation}`);
  console.log(`Juror 1 stake: ${hre.ethers.formatEther(juror1Data.stakedAmount)} ETH\n`);

  console.log("Simulation completed successfully!");
  console.log("\nNext steps would include:");
  console.log("- Evidence submission");
  console.log("- Jury selection via VRF");
  console.log("- Commit-reveal voting");
  console.log("- Ruling execution");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

