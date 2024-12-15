const hre = require("hardhat");

/**
 * Estimate gas costs for common operations
 */
async function main() {
  console.log("Estimating gas costs for QuillArbiter operations...\n");

  const [owner, plaintiff, defendant, juror] = await hre.ethers.getSigners();

  // Deploy contracts for testing
  const DisputeManager = await hre.ethers.getContractFactory("DisputeManager");
  const disputeManager = await DisputeManager.deploy(hre.ethers.parseEther("0.01"));
  await disputeManager.waitForDeployment();

  const EvidenceVault = await hre.ethers.getContractFactory("EvidenceVault");
  const evidenceVault = await EvidenceVault.deploy(await disputeManager.getAddress());
  await evidenceVault.waitForDeployment();

  const JuryPool = await hre.ethers.getContractFactory("JuryPool");
  const juryPool = await JuryPool.deploy();
  await juryPool.waitForDeployment();

  // Get current gas price
  const feeData = await hre.ethers.provider.getFeeData();
  const gasPrice = feeData.gasPrice;

  console.log(`Current gas price: ${hre.ethers.formatUnits(gasPrice, "gwei")} gwei\n`);

  // Estimate operations
  console.log("=== Gas Estimates ===\n");

  // File dispute
  const fileDisputeGas = await disputeManager.fileDispute.estimateGas(
    defendant.address,
    "QmTest",
    hre.ethers.ZeroAddress,
    hre.ethers.parseEther("1.0"),
    { value: hre.ethers.parseEther("0.01") }
  );
  console.log(`File Dispute: ${fileDisputeGas.toString()} gas`);
  console.log(`  Cost: ${hre.ethers.formatEther(fileDisputeGas * gasPrice)} ETH\n`);

  // File dispute first to get ID
  await disputeManager.connect(plaintiff).fileDispute(
    defendant.address,
    "QmTest",
    hre.ethers.ZeroAddress,
    hre.ethers.parseEther("1.0"),
    { value: hre.ethers.parseEther("0.01") }
  );

  // Submit evidence
  const submitEvidenceGas = await evidenceVault.connect(plaintiff).submitEvidence.estimateGas(
    1,
    hre.ethers.keccak256(hre.ethers.toUtf8Bytes("evidence")),
    "QmEvidence"
  );
  console.log(`Submit Evidence: ${submitEvidenceGas.toString()} gas`);
  console.log(`  Cost: ${hre.ethers.formatEther(submitEvidenceGas * gasPrice)} ETH\n`);

  // Stake as juror
  const stakeGas = await juryPool.connect(juror).stake.estimateGas({
    value: hre.ethers.parseEther("0.1")
  });
  console.log(`Stake as Juror: ${stakeGas.toString()} gas`);
  console.log(`  Cost: ${hre.ethers.formatEther(stakeGas * gasPrice)} ETH\n`);

  console.log("=== Total Estimated Costs ===\n");
  const totalGas = fileDisputeGas + submitEvidenceGas + stakeGas;
  console.log(`Total gas: ${totalGas.toString()}`);
  console.log(`Total cost: ${hre.ethers.formatEther(totalGas * gasPrice)} ETH`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

