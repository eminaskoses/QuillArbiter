const hre = require("hardhat");
const fs = require("fs");

/**
 * Verify all deployed contracts on Etherscan
 */
async function main() {
  console.log("Starting contract verification...");

  // Load deployment info
  if (!fs.existsSync("deployment-info.json")) {
    console.error("deployment-info.json not found. Please deploy contracts first.");
    process.exit(1);
  }

  const deploymentInfo = JSON.parse(fs.readFileSync("deployment-info.json", "utf8"));
  const contracts = deploymentInfo.contracts;

  // Configuration
  const disputeFee = hre.ethers.parseEther("0.01");
  const vrfCoordinator = "0x41034678D6C633D8a95c75e1138A360a28bA15d1";
  const keyHash = "0x5f0e69e6cb5f0c22e8c7a3d34aeaf0e9e2b1f58c4e7b2a8d1f0e69e6cb5f0c22";
  const subscriptionId = 0;

  try {
    // Verify DisputeManager
    console.log("\nVerifying DisputeManager...");
    await hre.run("verify:verify", {
      address: contracts.DisputeManager,
      constructorArguments: [disputeFee],
    });
    console.log("DisputeManager verified!");

    // Verify EvidenceVault
    console.log("\nVerifying EvidenceVault...");
    await hre.run("verify:verify", {
      address: contracts.EvidenceVault,
      constructorArguments: [contracts.DisputeManager],
    });
    console.log("EvidenceVault verified!");

    // Verify JuryPool
    console.log("\nVerifying JuryPool...");
    await hre.run("verify:verify", {
      address: contracts.JuryPool,
      constructorArguments: [],
    });
    console.log("JuryPool verified!");

    // Verify JurySelection
    console.log("\nVerifying JurySelection...");
    await hre.run("verify:verify", {
      address: contracts.JurySelection,
      constructorArguments: [
        vrfCoordinator,
        keyHash,
        subscriptionId,
        contracts.JuryPool,
      ],
    });
    console.log("JurySelection verified!");

    // Verify VotingCourt
    console.log("\nVerifying VotingCourt...");
    await hre.run("verify:verify", {
      address: contracts.VotingCourt,
      constructorArguments: [contracts.JurySelection],
    });
    console.log("VotingCourt verified!");

    // Verify RulingExecutor
    console.log("\nVerifying RulingExecutor...");
    await hre.run("verify:verify", {
      address: contracts.RulingExecutor,
      constructorArguments: [
        contracts.DisputeManager,
        contracts.VotingCourt,
        contracts.JuryPool,
      ],
    });
    console.log("RulingExecutor verified!");

    // Verify AppealBoard
    console.log("\nVerifying AppealBoard...");
    await hre.run("verify:verify", {
      address: contracts.AppealBoard,
      constructorArguments: [contracts.DisputeManager],
    });
    console.log("AppealBoard verified!");

    console.log("\n=== All contracts verified successfully! ===");
  } catch (error) {
    if (error.message.includes("Already Verified")) {
      console.log("Contract already verified!");
    } else {
      console.error("Verification error:", error);
    }
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

