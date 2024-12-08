const { expect } = require("chai");
const { ethers } = require("hardhat");
const { time } = require("@nomicfoundation/hardhat-network-helpers");

describe("JuryPool", function () {
  let juryPool;
  let owner, juror1, juror2, juror3, system;
  const minStake = ethers.parseEther("0.1");

  beforeEach(async function () {
    [owner, juror1, juror2, juror3, system] = await ethers.getSigners();

    const JuryPool = await ethers.getContractFactory("JuryPool");
    juryPool = await JuryPool.deploy();
    await juryPool.waitForDeployment();

    const SYSTEM_ROLE = ethers.keccak256(ethers.toUtf8Bytes("SYSTEM_ROLE"));
    await juryPool.grantRole(SYSTEM_ROLE, system.address);
  });

  describe("Staking", function () {
    it("Should allow juror to stake tokens", async function () {
      await expect(
        juryPool.connect(juror1).stake({ value: minStake })
      )
        .to.emit(juryPool, "JurorStaked")
        .withArgs(juror1.address, minStake, minStake, await ethers.provider.getBlock("latest").then(b => b ? b.timestamp + 1 : 0));
    });

    it("Should reject stake below minimum amount", async function () {
      const insufficientStake = ethers.parseEther("0.05");
      await expect(
        juryPool.connect(juror1).stake({ value: insufficientStake })
      ).to.be.revertedWith("Insufficient stake amount");
    });

    it("Should allow existing juror to add more stake", async function () {
      await juryPool.connect(juror1).stake({ value: minStake });
      
      const additionalStake = ethers.parseEther("0.2");
      await juryPool.connect(juror1).stake({ value: additionalStake });

      const juror = await juryPool.getJuror(juror1.address);
      expect(juror.stakedAmount).to.equal(minStake + additionalStake);
    });

    it("Should initialize new juror with correct reputation", async function () {
      await juryPool.connect(juror1).stake({ value: minStake });

      const juror = await juryPool.getJuror(juror1.address);
      expect(juror.reputation).to.equal(100);
      expect(juror.isActive).to.be.true;
    });
  });

  describe("Withdrawing", function () {
    beforeEach(async function () {
      await juryPool.connect(juror1).stake({ value: minStake });
    });

    it("Should allow withdrawal after lock period", async function () {
      await time.increase(30 * 24 * 60 * 60 + 1); // Advance 30 days + 1 second

      const withdrawAmount = ethers.parseEther("0.05");
      await expect(
        juryPool.connect(juror1).withdraw(withdrawAmount)
      ).to.emit(juryPool, "JurorWithdrawn");
    });

    it("Should reject withdrawal before lock period", async function () {
      const withdrawAmount = ethers.parseEther("0.05");
      await expect(
        juryPool.connect(juror1).withdraw(withdrawAmount)
      ).to.be.revertedWith("Lock period not ended");
    });

    it("Should reject withdrawal of more than staked", async function () {
      await time.increase(30 * 24 * 60 * 60 + 1);

      const excessiveAmount = ethers.parseEther("1.0");
      await expect(
        juryPool.connect(juror1).withdraw(excessiveAmount)
      ).to.be.revertedWith("Insufficient staked amount");
    });

    it("Should deactivate juror if stake falls below minimum", async function () {
      await time.increase(30 * 24 * 60 * 60 + 1);

      const withdrawAmount = ethers.parseEther("0.05");
      await juryPool.connect(juror1).withdraw(withdrawAmount);

      const juror = await juryPool.getJuror(juror1.address);
      expect(juror.isActive).to.be.false;
    });
  });

  describe("Slashing", function () {
    beforeEach(async function () {
      await juryPool.connect(juror1).stake({ value: minStake });
    });

    it("Should allow system role to slash juror", async function () {
      const slashAmount = ethers.parseEther("0.02");

      await expect(
        juryPool.connect(system).slash(juror1.address, slashAmount)
      )
        .to.emit(juryPool, "JurorSlashed")
        .withArgs(juror1.address, slashAmount, minStake - slashAmount, await ethers.provider.getBlock("latest").then(b => b ? b.timestamp + 1 : 0));
    });

    it("Should not allow non-system role to slash", async function () {
      const slashAmount = ethers.parseEther("0.02");

      await expect(
        juryPool.connect(juror2).slash(juror1.address, slashAmount)
      ).to.be.reverted;
    });

    it("Should deactivate juror if slashed below minimum", async function () {
      const largeSlash = ethers.parseEther("0.09");
      await juryPool.connect(system).slash(juror1.address, largeSlash);

      const juror = await juryPool.getJuror(juror1.address);
      expect(juror.isActive).to.be.false;
    });
  });

  describe("Reputation System", function () {
    beforeEach(async function () {
      await juryPool.connect(juror1).stake({ value: minStake });
    });

    it("Should increase reputation on correct vote", async function () {
      await juryPool.connect(system).updateReputation(juror1.address, true);

      const juror = await juryPool.getJuror(juror1.address);
      expect(juror.reputation).to.equal(105); // 100 * 1.05
      expect(juror.correctVotes).to.equal(1);
      expect(juror.totalVotes).to.equal(1);
    });

    it("Should decrease reputation on incorrect vote", async function () {
      await juryPool.connect(system).updateReputation(juror1.address, false);

      const juror = await juryPool.getJuror(juror1.address);
      expect(juror.reputation).to.equal(90); // 100 * 0.9
      expect(juror.correctVotes).to.equal(0);
      expect(juror.totalVotes).to.equal(1);
    });

    it("Should cap reputation at 1000", async function () {
      // Increase reputation multiple times
      for (let i = 0; i < 50; i++) {
        await juryPool.connect(system).updateReputation(juror1.address, true);
      }

      const juror = await juryPool.getJuror(juror1.address);
      expect(juror.reputation).to.equal(1000);
    });
  });

  describe("Eligibility", function () {
    it("Should return true for eligible juror", async function () {
      await juryPool.connect(juror1).stake({ value: minStake });

      expect(await juryPool.isEligibleJuror(juror1.address)).to.be.true;
    });

    it("Should return false for inactive juror", async function () {
      await juryPool.connect(juror1).stake({ value: minStake });
      
      // Slash to make inactive
      await juryPool.connect(system).slash(juror1.address, ethers.parseEther("0.09"));

      expect(await juryPool.isEligibleJuror(juror1.address)).to.be.false;
    });

    it("Should return false for non-staked address", async function () {
      expect(await juryPool.isEligibleJuror(juror2.address)).to.be.false;
    });
  });

  describe("Active Jurors List", function () {
    it("Should return list of active jurors", async function () {
      await juryPool.connect(juror1).stake({ value: minStake });
      await juryPool.connect(juror2).stake({ value: minStake });
      await juryPool.connect(juror3).stake({ value: minStake });

      const activeJurors = await juryPool.getActiveJurors();
      expect(activeJurors.length).to.equal(3);
      expect(activeJurors).to.include(juror1.address);
      expect(activeJurors).to.include(juror2.address);
      expect(activeJurors).to.include(juror3.address);
    });

    it("Should remove juror from active list when deactivated", async function () {
      await juryPool.connect(juror1).stake({ value: minStake });
      await juryPool.connect(juror2).stake({ value: minStake });

      let activeJurors = await juryPool.getActiveJurors();
      expect(activeJurors.length).to.equal(2);

      // Slash juror1 to deactivate
      await juryPool.connect(system).slash(juror1.address, ethers.parseEther("0.09"));

      activeJurors = await juryPool.getActiveJurors();
      expect(activeJurors.length).to.equal(1);
      expect(activeJurors).to.not.include(juror1.address);
    });
  });
});

