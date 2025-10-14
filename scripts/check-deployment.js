const hre = require("hardhat");
const fs = require("fs");

/**
 * Check deployment status and contract health
 */
async function main() {
  console.log("Checking QuillArbiter deployment...\n");

  if (!fs.existsSync("deployment-info.json")) {
    console.error("❌ deployment-info.json not found");
    console.log("Run 'npm run deploy' first");
    process.exit(1);
  }

  const deploymentInfo = JSON.parse(fs.readFileSync("deployment-info.json", "utf8"));
  const contracts = deploymentInfo.contracts;

  console.log("Deployment Information:");
  console.log(`Network: ${deploymentInfo.network}`);
  console.log(`Deployer: ${deploymentInfo.deployer}`);
  console.log(`Timestamp: ${deploymentInfo.timestamp}\n`);

  // Check each contract
  console.log("Checking contract deployments...\n");

  for (const [name, address] of Object.entries(contracts)) {
    try {
      const code = await hre.ethers.provider.getCode(address);
      const isDeployed = code !== "0x";
      
      console.log(`${name}:`);
      console.log(`  Address: ${address}`);
      console.log(`  Status: ${isDeployed ? "✅ Deployed" : "❌ Not found"}`);
      
      if (isDeployed) {
        const contract = await hre.ethers.getContractAt(name, address);
        
        // Check contract-specific details
        if (name === "DisputeManager") {
          const fee = await contract.disputeFee();
          const total = await contract.getTotalDisputes();
          console.log(`  Dispute Fee: ${hre.ethers.formatEther(fee)} ETH`);
          console.log(`  Total Disputes: ${total}`);
        } else if (name === "JuryPool") {
          const minStake = await contract.minStakeAmount();
          const totalJurors = await contract.getTotalJurors();
          console.log(`  Min Stake: ${hre.ethers.formatEther(minStake)} ETH`);
          console.log(`  Active Jurors: ${totalJurors}`);
        }
      }
      console.log();
    } catch (error) {
      console.log(`  Error: ${error.message}\n`);
    }
  }

  console.log("Health check completed!");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

