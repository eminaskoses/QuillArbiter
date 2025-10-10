const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("AppealBoard", function () {
  let appealBoard;
  let disputeManager;
  let owner, plaintiff, defendant, arbitrator;
  const appealFee = ethers.parseEther("0.5");

  beforeEach(async function () {
    [owner, plaintiff, defendant, arbitrator] = await ethers.getSigners();

    // Deploy DisputeManager
    const DisputeManager = await ethers.getContractFactory("DisputeManager");
    disputeManager = await DisputeManager.deploy(ethers.parseEther("0.01"));
    await disputeManager.waitForDeployment();

    // Deploy AppealBoard
    const AppealBoard = await ethers.getContractFactory("AppealBoard");
    appealBoard = await AppealBoard.deploy(await disputeManager.getAddress());
    await appealBoard.waitForDeployment();

    // Grant arbitrator role
    const ARBITRATOR_ROLE = ethers.keccak256(ethers.toUtf8Bytes("ARBITRATOR_ROLE"));
    await appealBoard.grantRole(ARBITRATOR_ROLE, arbitrator.address);

    // Create and execute a dispute
    await disputeManager.connect(plaintiff).fileDispute(
      defendant.address,
      "QmTest",
      ethers.ZeroAddress,
      0,
      { value: ethers.parseEther("0.01") }
    );

    // Update status to Executed
    const SYSTEM_ROLE = ethers.keccak256(ethers.toUtf8Bytes("SYSTEM_ROLE"));
    await disputeManager.grantRole(SYSTEM_ROLE, owner.address);
    await disputeManager.updateDisputeStatus(1, 5); // Executed
  });

  describe("Filing Appeals", function () {
    it("Should allow dispute party to file appeal", async function () {
      const reason = "Unfair ruling based on insufficient evidence";

      await expect(
        appealBoard.connect(plaintiff).fileAppeal(1, reason, {
          value: appealFee,
        })
      )
        .to.emit(appealBoard, "AppealFiled")
        .withArgs(1, 1, plaintiff.address, appealFee, await ethers.provider.getBlock("latest").then(b => b ? b.timestamp + 1 : 0));
    });

    it("Should reject appeal with insufficient fee", async function () {
      const insufficientFee = ethers.parseEther("0.1");

      await expect(
        appealBoard.connect(plaintiff).fileAppeal(1, "Reason", {
          value: insufficientFee,
        })
      ).to.be.revertedWith("Insufficient appeal fee");
    });

    it("Should reject appeal from non-party", async function () {
      await expect(
        appealBoard.connect(owner).fileAppeal(1, "Reason", {
          value: appealFee,
        })
      ).to.be.revertedWith("Only dispute parties can appeal");
    });

    it("Should reject appeal without reason", async function () {
      await expect(
        appealBoard.connect(plaintiff).fileAppeal(1, "", {
          value: appealFee,
        })
      ).to.be.revertedWith("Reason required");
    });

    it("Should reject duplicate appeal", async function () {
      await appealBoard.connect(plaintiff).fileAppeal(1, "First appeal", {
        value: appealFee,
      });

      await expect(
        appealBoard.connect(defendant).fileAppeal(1, "Second appeal", {
          value: appealFee,
        })
      ).to.be.revertedWith("Active appeal exists");
    });
  });

  describe("Processing Appeals", function () {
    let appealId;

    beforeEach(async function () {
      const tx = await appealBoard.connect(plaintiff).fileAppeal(1, "Appeal reason", {
        value: appealFee,
      });
      appealId = 1;
    });

    it("Should allow arbitrator to accept appeal", async function () {
      await expect(
        appealBoard.connect(arbitrator).processAppeal(appealId, true)
      )
        .to.emit(appealBoard, "AppealProcessed")
        .withArgs(appealId, true, await ethers.provider.getBlock("latest").then(b => b ? b.timestamp + 1 : 0));
    });

    it("Should allow arbitrator to reject appeal", async function () {
      await expect(
        appealBoard.connect(arbitrator).processAppeal(appealId, false)
      )
        .to.emit(appealBoard, "AppealProcessed")
        .withArgs(appealId, false, await ethers.provider.getBlock("latest").then(b => b ? b.timestamp + 1 : 0));
    });

    it("Should not allow non-arbitrator to process", async function () {
      await expect(
        appealBoard.connect(plaintiff).processAppeal(appealId, true)
      ).to.be.reverted;
    });

    it("Should not allow double processing", async function () {
      await appealBoard.connect(arbitrator).processAppeal(appealId, true);

      await expect(
        appealBoard.connect(arbitrator).processAppeal(appealId, false)
      ).to.be.revertedWith("Appeal already processed");
    });
  });

  describe("Appeal Queries", function () {
    beforeEach(async function () {
      await appealBoard.connect(plaintiff).fileAppeal(1, "Appeal reason", {
        value: appealFee,
      });
    });

    it("Should return appeal details", async function () {
      const appeal = await appealBoard.getAppeal(1);
      expect(appeal.appealId).to.equal(1);
      expect(appeal.disputeId).to.equal(1);
      expect(appeal.appellant).to.equal(plaintiff.address);
      expect(appeal.processed).to.be.false;
    });

    it("Should return dispute appeals list", async function () {
      const appeals = await appealBoard.getDisputeAppeals(1);
      expect(appeals.length).to.equal(1);
      expect(appeals[0]).to.equal(1);
    });

    it("Should check if appeal is pending", async function () {
      expect(await appealBoard.isAppealPending(1)).to.be.true;

      const ARBITRATOR_ROLE = ethers.keccak256(ethers.toUtf8Bytes("ARBITRATOR_ROLE"));
      await appealBoard.connect(arbitrator).processAppeal(1, true);

      expect(await appealBoard.isAppealPending(1)).to.be.false;
    });

    it("Should return total appeals count", async function () {
      expect(await appealBoard.getTotalAppeals()).to.equal(1);
    });
  });

  describe("Fee Management", function () {
    it("Should allow admin to update appeal fee", async function () {
      const newFee = ethers.parseEther("1.0");
      await appealBoard.setAppealFee(newFee);
      expect(await appealBoard.appealFee()).to.equal(newFee);
    });

    it("Should allow admin to withdraw fees", async function () {
      await appealBoard.connect(plaintiff).fileAppeal(1, "Reason", {
        value: appealFee,
      });

      const initialBalance = await ethers.provider.getBalance(owner.address);
      await appealBoard.withdrawFees();
      const finalBalance = await ethers.provider.getBalance(owner.address);

      expect(finalBalance).to.be.gt(initialBalance);
    });
  });
});

