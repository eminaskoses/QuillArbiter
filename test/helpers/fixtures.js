const { ethers } = require("hardhat");

/**
 * Test fixtures for QuillArbiter
 */

async function deployDisputeManagerFixture() {
  const DisputeManager = await ethers.getContractFactory("DisputeManager");
  const disputeManager = await DisputeManager.deploy(ethers.parseEther("0.01"));
  await disputeManager.waitForDeployment();
  return disputeManager;
}

async function deployFullSystemFixture() {
  const [owner, plaintiff, defendant, juror1, juror2, juror3] = await ethers.getSigners();

  // Deploy DisputeManager
  const DisputeManager = await ethers.getContractFactory("DisputeManager");
  const disputeManager = await DisputeManager.deploy(ethers.parseEther("0.01"));
  await disputeManager.waitForDeployment();

  // Deploy EvidenceVault
  const EvidenceVault = await ethers.getContractFactory("EvidenceVault");
  const evidenceVault = await EvidenceVault.deploy(await disputeManager.getAddress());
  await evidenceVault.waitForDeployment();

  // Deploy JuryPool
  const JuryPool = await ethers.getContractFactory("JuryPool");
  const juryPool = await JuryPool.deploy();
  await juryPool.waitForDeployment();

  // Deploy AppealBoard
  const AppealBoard = await ethers.getContractFactory("AppealBoard");
  const appealBoard = await AppealBoard.deploy(await disputeManager.getAddress());
  await appealBoard.waitForDeployment();

  return {
    disputeManager,
    evidenceVault,
    juryPool,
    appealBoard,
    signers: { owner, plaintiff, defendant, juror1, juror2, juror3 }
  };
}

async function createDisputeFixture(disputeManager, plaintiff, defendant) {
  const tx = await disputeManager.connect(plaintiff).fileDispute(
    defendant.address,
    "QmTestDispute",
    ethers.ZeroAddress,
    ethers.parseEther("1.0"),
    { value: ethers.parseEther("0.01") }
  );
  await tx.wait();
  return 1; // First dispute ID
}

async function stakeJurorsFixture(juryPool, jurors) {
  const minStake = await juryPool.minStakeAmount();
  
  for (const juror of jurors) {
    await juryPool.connect(juror).stake({ value: minStake });
  }
}

module.exports = {
  deployDisputeManagerFixture,
  deployFullSystemFixture,
  createDisputeFixture,
  stakeJurorsFixture,
};

