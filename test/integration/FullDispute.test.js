const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Full Dispute Lifecycle Integration", function () {
  let disputeManager, evidenceVault, juryPool;
  let owner, plaintiff, defendant;

  before(async function () {
    [owner, plaintiff, defendant] = await ethers.getSigners();

    // Deploy all contracts
    const DisputeManager = await ethers.getContractFactory("DisputeManager");
    disputeManager = await DisputeManager.deploy(ethers.parseEther("0.01"));
    await disputeManager.waitForDeployment();

    const EvidenceVault = await ethers.getContractFactory("EvidenceVault");
    evidenceVault = await EvidenceVault.deploy(await disputeManager.getAddress());
    await evidenceVault.waitForDeployment();

    const JuryPool = await ethers.getContractFactory("JuryPool");
    juryPool = await JuryPool.deploy();
    await juryPool.waitForDeployment();
  });

  it("Should complete a full dispute flow", async function () {
    // File dispute
    const disputeFee = await disputeManager.disputeFee();
    await disputeManager.connect(plaintiff).fileDispute(
      defendant.address,
      "QmTestDispute",
      ethers.ZeroAddress,
      ethers.parseEther("1.0"),
      { value: disputeFee }
    );

    const dispute = await disputeManager.getDisputeInfo(1);
    expect(dispute.plaintiff).to.equal(plaintiff.address);

    // Submit evidence
    const evidenceHash = ethers.keccak256(ethers.toUtf8Bytes("evidence data"));
    await evidenceVault.connect(plaintiff).submitEvidence(
      1,
      evidenceHash,
      "QmEvidenceCID"
    );

    const evidenceList = await evidenceVault.getDisputeEvidenceList(1);
    expect(evidenceList.length).to.equal(1);

    // Verify integration works
    expect(await disputeManager.getTotalDisputes()).to.equal(1);
    expect(await evidenceVault.getTotalEvidenceCount()).to.equal(1);
  });
});

