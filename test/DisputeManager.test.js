const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("DisputeManager", function () {
  let disputeManager;
  let owner, plaintiff, defendant, arbitrator;
  const disputeFee = ethers.parseEther("0.01");

  beforeEach(async function () {
    [owner, plaintiff, defendant, arbitrator] = await ethers.getSigners();

    const DisputeManager = await ethers.getContractFactory("DisputeManager");
    disputeManager = await DisputeManager.deploy(disputeFee);
    await disputeManager.waitForDeployment();
  });

  describe("Deployment", function () {
    it("Should set the correct dispute fee", async function () {
      expect(await disputeManager.disputeFee()).to.equal(disputeFee);
    });

    it("Should grant admin role to deployer", async function () {
      const DEFAULT_ADMIN_ROLE = await disputeManager.DEFAULT_ADMIN_ROLE();
      expect(
        await disputeManager.hasRole(DEFAULT_ADMIN_ROLE, owner.address)
      ).to.be.true;
    });
  });

  describe("Filing Disputes", function () {
    it("Should allow filing a dispute with correct fee", async function () {
      const metadataCID = "QmTest123";
      const escrowContract = ethers.ZeroAddress;
      const escrowAmount = ethers.parseEther("1.0");

      await expect(
        disputeManager
          .connect(plaintiff)
          .fileDispute(defendant.address, metadataCID, escrowContract, escrowAmount, {
            value: disputeFee,
          })
      )
        .to.emit(disputeManager, "DisputeFiled")
        .withArgs(1, plaintiff.address, defendant.address, metadataCID, await ethers.provider.getBlock("latest").then(b => b ? b.timestamp + 1 : 0));
    });

    it("Should reject dispute with insufficient fee", async function () {
      const metadataCID = "QmTest123";
      const insufficientFee = ethers.parseEther("0.005");

      await expect(
        disputeManager
          .connect(plaintiff)
          .fileDispute(defendant.address, metadataCID, ethers.ZeroAddress, 0, {
            value: insufficientFee,
          })
      ).to.be.revertedWith("Insufficient dispute fee");
    });

    it("Should not allow self-disputes", async function () {
      const metadataCID = "QmTest123";

      await expect(
        disputeManager
          .connect(plaintiff)
          .fileDispute(plaintiff.address, metadataCID, ethers.ZeroAddress, 0, {
            value: disputeFee,
          })
      ).to.be.revertedWith("Cannot dispute with yourself");
    });

    it("Should increment dispute counter", async function () {
      const metadataCID = "QmTest123";

      await disputeManager
        .connect(plaintiff)
        .fileDispute(defendant.address, metadataCID, ethers.ZeroAddress, 0, {
          value: disputeFee,
        });

      const dispute = await disputeManager.getDisputeInfo(1);
      expect(dispute.disputeId).to.equal(1);
    });
  });

  describe("Dispute Status Management", function () {
    let disputeId;

    beforeEach(async function () {
      const metadataCID = "QmTest123";
      const tx = await disputeManager
        .connect(plaintiff)
        .fileDispute(defendant.address, metadataCID, ethers.ZeroAddress, 0, {
          value: disputeFee,
        });
      
      const receipt = await tx.wait();
      disputeId = 1;
    });

    it("Should allow authorized role to update status", async function () {
      const SYSTEM_ROLE = ethers.keccak256(ethers.toUtf8Bytes("SYSTEM_ROLE"));
      await disputeManager.grantRole(SYSTEM_ROLE, arbitrator.address);

      await expect(
        disputeManager.connect(arbitrator).updateDisputeStatus(disputeId, 1)
      ).to.emit(disputeManager, "DisputeStatusChanged");
    });

    it("Should allow parties to close dispute", async function () {
      await expect(
        disputeManager.connect(plaintiff).closeDispute(disputeId)
      ).to.emit(disputeManager, "DisputeClosed");
    });
  });

  describe("Dispute Information", function () {
    it("Should return correct dispute information", async function () {
      const metadataCID = "QmTest123";
      const escrowAmount = ethers.parseEther("1.0");

      await disputeManager
        .connect(plaintiff)
        .fileDispute(defendant.address, metadataCID, ethers.ZeroAddress, escrowAmount, {
          value: disputeFee,
        });

      const dispute = await disputeManager.getDisputeInfo(1);
      expect(dispute.plaintiff).to.equal(plaintiff.address);
      expect(dispute.defendant).to.equal(defendant.address);
      expect(dispute.metadataCID).to.equal(metadataCID);
      expect(dispute.escrowAmount).to.equal(escrowAmount);
    });

    it("Should revert when querying non-existent dispute", async function () {
      await expect(
        disputeManager.getDisputeInfo(999)
      ).to.be.revertedWith("Dispute does not exist");
    });
  });

  describe("Fee Management", function () {
    it("Should allow admin to update dispute fee", async function () {
      const newFee = ethers.parseEther("0.02");
      await disputeManager.setDisputeFee(newFee);
      expect(await disputeManager.disputeFee()).to.equal(newFee);
    });

    it("Should allow admin to withdraw fees", async function () {
      const metadataCID = "QmTest123";
      
      await disputeManager
        .connect(plaintiff)
        .fileDispute(defendant.address, metadataCID, ethers.ZeroAddress, 0, {
          value: disputeFee,
        });

      const initialBalance = await ethers.provider.getBalance(owner.address);
      await disputeManager.withdrawFees();
      const finalBalance = await ethers.provider.getBalance(owner.address);

      expect(finalBalance).to.be.gt(initialBalance);
    });
  });
});

