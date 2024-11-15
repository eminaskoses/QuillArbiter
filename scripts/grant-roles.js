const hre = require("hardhat");
const fs = require("fs");

/**
 * Grant necessary roles to contracts
 */
async function main() {
  console.log("Granting roles to contracts...\n");

  if (!fs.existsSync("deployment-info.json")) {
    console.error("deployment-info.json not found");
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
  const jurySelection = await hre.ethers.getContractAt(
    "JurySelection",
    contracts.JurySelection
  );
  const votingCourt = await hre.ethers.getContractAt(
    "VotingCourt",
    contracts.VotingCourt
  );

  // Define roles
  const SYSTEM_ROLE = hre.ethers.keccak256(hre.ethers.toUtf8Bytes("SYSTEM_ROLE"));

  console.log("Granting SYSTEM_ROLE...");

  // DisputeManager roles
  console.log("- VotingCourt -> DisputeManager");
  await disputeManager.grantRole(SYSTEM_ROLE, contracts.VotingCourt);
  
  console.log("- RulingExecutor -> DisputeManager");
  await disputeManager.grantRole(SYSTEM_ROLE, contracts.RulingExecutor);
  
  console.log("- AppealBoard -> DisputeManager");
  await disputeManager.grantRole(SYSTEM_ROLE, contracts.AppealBoard);

  // JuryPool roles
  console.log("- JurySelection -> JuryPool");
  await juryPool.grantRole(SYSTEM_ROLE, contracts.JurySelection);
  
  console.log("- VotingCourt -> JuryPool");
  await juryPool.grantRole(SYSTEM_ROLE, contracts.VotingCourt);

  // JurySelection roles
  console.log("- VotingCourt -> JurySelection");
  await jurySelection.grantRole(SYSTEM_ROLE, contracts.VotingCourt);

  // VotingCourt roles
  console.log("- RulingExecutor -> VotingCourt");
  await votingCourt.grantRole(SYSTEM_ROLE, contracts.RulingExecutor);

  console.log("\n✅ All roles granted successfully!");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

