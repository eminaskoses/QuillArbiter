const hre = require("hardhat");

async function main() {
  console.log("Starting QuillArbiter deployment...");

  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with account:", deployer.address);

  // Configuration
  const disputeFee = hre.ethers.parseEther("0.01");
  const appealFee = hre.ethers.parseEther("0.5");
  
  // Chainlink VRF Configuration (Optimism Sepolia testnet)
  const vrfCoordinator = "0x41034678D6C633D8a95c75e1138A360a28bA15d1";
  const keyHash = "0x5f0e69e6cb5f0c22e8c7a3d34aeaf0e9e2b1f58c4e7b2a8d1f0e69e6cb5f0c22";
  const subscriptionId = 0; // Replace with actual subscription ID

  // Deploy DisputeManager
  console.log("\nDeploying DisputeManager...");
  const DisputeManager = await hre.ethers.getContractFactory("DisputeManager");
  const disputeManager = await DisputeManager.deploy(disputeFee);
  await disputeManager.waitForDeployment();
  const disputeManagerAddress = await disputeManager.getAddress();
  console.log("DisputeManager deployed to:", disputeManagerAddress);

  // Deploy EvidenceVault
  console.log("\nDeploying EvidenceVault...");
  const EvidenceVault = await hre.ethers.getContractFactory("EvidenceVault");
  const evidenceVault = await EvidenceVault.deploy(disputeManagerAddress);
  await evidenceVault.waitForDeployment();
  const evidenceVaultAddress = await evidenceVault.getAddress();
  console.log("EvidenceVault deployed to:", evidenceVaultAddress);

  // Deploy JuryPool
  console.log("\nDeploying JuryPool...");
  const JuryPool = await hre.ethers.getContractFactory("JuryPool");
  const juryPool = await JuryPool.deploy();
  await juryPool.waitForDeployment();
  const juryPoolAddress = await juryPool.getAddress();
  console.log("JuryPool deployed to:", juryPoolAddress);

  // Deploy JurySelection
  console.log("\nDeploying JurySelection...");
  const JurySelection = await hre.ethers.getContractFactory("JurySelection");
  const jurySelection = await JurySelection.deploy(
    vrfCoordinator,
    keyHash,
    subscriptionId,
    juryPoolAddress
  );
  await jurySelection.waitForDeployment();
  const jurySelectionAddress = await jurySelection.getAddress();
  console.log("JurySelection deployed to:", jurySelectionAddress);

  // Deploy VotingCourt
  console.log("\nDeploying VotingCourt...");
  const VotingCourt = await hre.ethers.getContractFactory("VotingCourt");
  const votingCourt = await VotingCourt.deploy(jurySelectionAddress);
  await votingCourt.waitForDeployment();
  const votingCourtAddress = await votingCourt.getAddress();
  console.log("VotingCourt deployed to:", votingCourtAddress);

  // Deploy RulingExecutor
  console.log("\nDeploying RulingExecutor...");
  const RulingExecutor = await hre.ethers.getContractFactory("RulingExecutor");
  const rulingExecutor = await RulingExecutor.deploy(
    disputeManagerAddress,
    votingCourtAddress,
    juryPoolAddress
  );
  await rulingExecutor.waitForDeployment();
  const rulingExecutorAddress = await rulingExecutor.getAddress();
  console.log("RulingExecutor deployed to:", rulingExecutorAddress);

  // Deploy AppealBoard
  console.log("\nDeploying AppealBoard...");
  const AppealBoard = await hre.ethers.getContractFactory("AppealBoard");
  const appealBoard = await AppealBoard.deploy(disputeManagerAddress);
  await appealBoard.waitForDeployment();
  const appealBoardAddress = await appealBoard.getAddress();
  console.log("AppealBoard deployed to:", appealBoardAddress);

  // Grant roles
  console.log("\nGranting system roles...");
  const SYSTEM_ROLE = hre.ethers.keccak256(hre.ethers.toUtf8Bytes("SYSTEM_ROLE"));
  
  await disputeManager.grantRole(SYSTEM_ROLE, votingCourtAddress);
  await disputeManager.grantRole(SYSTEM_ROLE, rulingExecutorAddress);
  await disputeManager.grantRole(SYSTEM_ROLE, appealBoardAddress);
  
  await juryPool.grantRole(SYSTEM_ROLE, jurySelectionAddress);
  await juryPool.grantRole(SYSTEM_ROLE, votingCourtAddress);
  
  await jurySelection.grantRole(SYSTEM_ROLE, votingCourtAddress);
  await votingCourt.grantRole(SYSTEM_ROLE, rulingExecutorAddress);

  console.log("\n=== Deployment Summary ===");
  console.log("DisputeManager:", disputeManagerAddress);
  console.log("EvidenceVault:", evidenceVaultAddress);
  console.log("JuryPool:", juryPoolAddress);
  console.log("JurySelection:", jurySelectionAddress);
  console.log("VotingCourt:", votingCourtAddress);
  console.log("RulingExecutor:", rulingExecutorAddress);
  console.log("AppealBoard:", appealBoardAddress);
  console.log("\nDeployment completed successfully!");

  // Save deployment addresses
  const fs = require("fs");
  const deploymentInfo = {
    network: hre.network.name,
    deployer: deployer.address,
    timestamp: new Date().toISOString(),
    contracts: {
      DisputeManager: disputeManagerAddress,
      EvidenceVault: evidenceVaultAddress,
      JuryPool: juryPoolAddress,
      JurySelection: jurySelectionAddress,
      VotingCourt: votingCourtAddress,
      RulingExecutor: rulingExecutorAddress,
      AppealBoard: appealBoardAddress,
    },
  };

  fs.writeFileSync(
    "deployment-info.json",
    JSON.stringify(deploymentInfo, null, 2)
  );
  console.log("\nDeployment info saved to deployment-info.json");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

