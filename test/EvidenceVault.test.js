const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("EvidenceVault", function () {
  let evidenceVault;
  let disputeManager;
  let owner, plaintiff, defendant, verifier;
  const disputeId = 1;

  beforeEach(async function () {
    [owner, plaintiff, defendant, verifier] = await ethers.getSigners();

    // Deploy DisputeManager
    const DisputeManager = await ethers.getContractFactory("DisputeManager");
    disputeManager = await DisputeManager.deploy(ethers.parseEther("0.01"));
    await disputeManager.waitForDeployment();

    // Deploy EvidenceVault
    const EvidenceVault = await ethers.getContractFactory("EvidenceVault");
    evidenceVault = await EvidenceVault.deploy(await disputeManager.getAddress());
    await evidenceVault.waitForDeployment();

    // Grant verifier role
    const VERIFIER_ROLE = ethers.keccak256(ethers.toUtf8Bytes("VERIFIER_ROLE"));
    await evidenceVault.grantRole(VERIFIER_ROLE, verifier.address);

    // Create a dispute
    await disputeManager.connect(plaintiff).fileDispute(
      defendant.address,
      "QmTest",
      ethers.ZeroAddress,
      0,
      { value: ethers.parseEther("0.01") }
    );
  });

  describe("Evidence Submission", function () {
    it("Should allow plaintiff to submit evidence", async function () {
      const evidenceHash = ethers.keccak256(ethers.toUtf8Bytes("evidence data"));
      const encryptedCID = "QmEncryptedEvidence123";

      await expect(
        evidenceVault.connect(plaintiff).submitEvidence(
          disputeId,
          evidenceHash,
          encryptedCID
        )
      )
        .to.emit(evidenceVault, "EvidenceSubmitted")
        .withArgs(1, disputeId, plaintiff.address, evidenceHash, await ethers.provider.getBlock("latest").then(b => b ? b.timestamp + 1 : 0));
    });

    it("Should allow defendant to submit evidence", async function () {
      const evidenceHash = ethers.keccak256(ethers.toUtf8Bytes("defense evidence"));
      const encryptedCID = "QmDefenseEvidence456";

      await expect(
        evidenceVault.connect(defendant).submitEvidence(
          disputeId,
          evidenceHash,
          encryptedCID
        )
      ).to.emit(evidenceVault, "EvidenceSubmitted");
    });

    it("Should reject evidence from non-parties", async function () {
      const evidenceHash = ethers.keccak256(ethers.toUtf8Bytes("evidence"));
      const encryptedCID = "QmEvidence";

      await expect(
        evidenceVault.connect(owner).submitEvidence(
          disputeId,
          evidenceHash,
          encryptedCID
        )
      ).to.be.revertedWith("Only dispute parties can submit evidence");
    });

    it("Should reject invalid evidence hash", async function () {
      await expect(
        evidenceVault.connect(plaintiff).submitEvidence(
          disputeId,
          ethers.ZeroHash,
          "QmEvidence"
        )
      ).to.be.revertedWith("Invalid evidence hash");
    });

    it("Should reject empty CID", async function () {
      const evidenceHash = ethers.keccak256(ethers.toUtf8Bytes("evidence"));

      await expect(
        evidenceVault.connect(plaintiff).submitEvidence(
          disputeId,
          evidenceHash,
          ""
        )
      ).to.be.revertedWith("Encrypted CID required");
    });
  });

  describe("Evidence Verification", function () {
    let evidenceId;
    let evidenceHash;

    beforeEach(async function () {
      evidenceHash = ethers.keccak256(ethers.toUtf8Bytes("evidence data"));
      const tx = await evidenceVault.connect(plaintiff).submitEvidence(
        disputeId,
        evidenceHash,
        "QmEvidence"
      );
      evidenceId = 1;
    });

    it("Should verify evidence with correct hash", async function () {
      await expect(
        evidenceVault.connect(verifier).verifyEvidence(evidenceId, evidenceHash)
      )
        .to.emit(evidenceVault, "EvidenceVerified")
        .withArgs(evidenceId, true);
    });

    it("Should reject verification with wrong hash", async function () {
      const wrongHash = ethers.keccak256(ethers.toUtf8Bytes("wrong data"));

      await expect(
        evidenceVault.connect(verifier).verifyEvidence(evidenceId, wrongHash)
      )
        .to.emit(evidenceVault, "EvidenceVerified")
        .withArgs(evidenceId, false);
    });

    it("Should only allow verifier role to verify", async function () {
      await expect(
        evidenceVault.connect(plaintiff).verifyEvidence(evidenceId, evidenceHash)
      ).to.be.reverted;
    });
  });

  describe("Evidence Queries", function () {
    beforeEach(async function () {
      const hash1 = ethers.keccak256(ethers.toUtf8Bytes("evidence 1"));
      const hash2 = ethers.keccak256(ethers.toUtf8Bytes("evidence 2"));

      await evidenceVault.connect(plaintiff).submitEvidence(disputeId, hash1, "QmEvidence1");
      await evidenceVault.connect(defendant).submitEvidence(disputeId, hash2, "QmEvidence2");
    });

    it("Should return evidence details", async function () {
      const evidence = await evidenceVault.getEvidence(1);
      expect(evidence.evidenceId).to.equal(1);
      expect(evidence.disputeId).to.equal(disputeId);
      expect(evidence.submitter).to.equal(plaintiff.address);
    });

    it("Should return dispute evidence list", async function () {
      const evidenceList = await evidenceVault.getDisputeEvidenceList(disputeId);
      expect(evidenceList.length).to.equal(2);
      expect(evidenceList[0]).to.equal(1);
      expect(evidenceList[1]).to.equal(2);
    });

    it("Should return submitter evidence list", async function () {
      const plaintiffEvidence = await evidenceVault.getSubmitterEvidenceList(plaintiff.address);
      expect(plaintiffEvidence.length).to.equal(1);
      expect(plaintiffEvidence[0]).to.equal(1);
    });

    it("Should return total evidence count", async function () {
      const count = await evidenceVault.getTotalEvidenceCount();
      expect(count).to.equal(2);
    });

    it("Should return dispute evidence count", async function () {
      const count = await evidenceVault.getDisputeEvidenceCount(disputeId);
      expect(count).to.equal(2);
    });

    it("Should check if evidence exists", async function () {
      expect(await evidenceVault.evidenceExists(1)).to.be.true;
      expect(await evidenceVault.evidenceExists(999)).to.be.false;
    });
  });
});

