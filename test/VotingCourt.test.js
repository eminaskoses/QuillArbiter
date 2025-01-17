const { expect } = require("chai");
const { ethers } = require("hardhat");
const { time } = require("@nomicfoundation/hardhat-network-helpers");

describe("VotingCourt", function () {
  let votingCourt;
  let jurySelection;
  let owner, juror1, juror2, juror3, system;
  const disputeId = 1;

  beforeEach(async function () {
    [owner, juror1, juror2, juror3, system] = await ethers.getSigners();

    // Deploy mock JurySelection
    const MockJurySelection = await ethers.getContractFactory("MockJurySelection");
    jurySelection = await MockJurySelection.deploy();
    await jurySelection.waitForDeployment();

    // Deploy VotingCourt
    const VotingCourt = await ethers.getContractFactory("VotingCourt");
    votingCourt = await VotingCourt.deploy(await jurySelection.getAddress());
    await votingCourt.waitForDeployment();

    // Grant system role
    const SYSTEM_ROLE = ethers.keccak256(ethers.toUtf8Bytes("SYSTEM_ROLE"));
    await votingCourt.grantRole(SYSTEM_ROLE, system.address);

    // Mock selected jurors
    await jurySelection.addSelectedJuror(disputeId, juror1.address);
    await jurySelection.addSelectedJuror(disputeId, juror2.address);
    await jurySelection.addSelectedJuror(disputeId, juror3.address);
  });

  describe("Voting Initialization", function () {
    it("Should initialize voting session", async function () {
      await votingCourt.connect(system).initializeVoting(disputeId);

      const session = await votingCourt.getVotingSession(disputeId);
      expect(session.disputeId).to.equal(disputeId);
      expect(session.finalized).to.be.false;
    });

    it("Should not allow duplicate initialization", async function () {
      await votingCourt.connect(system).initializeVoting(disputeId);

      await expect(
        votingCourt.connect(system).initializeVoting(disputeId)
      ).to.be.revertedWith("Voting already initialized");
    });
  });

  describe("Commit Phase", function () {
    beforeEach(async function () {
      await votingCourt.connect(system).initializeVoting(disputeId);
    });

    it("Should allow selected juror to commit vote", async function () {
      const verdict = 1; // PlaintiffWins
      const salt = ethers.encodeBytes32String("secret");
      const voteHash = ethers.keccak256(
        ethers.AbiCoder.defaultAbiCoder().encode(["uint256", "bytes32"], [verdict, salt])
      );

      await expect(
        votingCourt.connect(juror1).commitVote(disputeId, voteHash)
      )
        .to.emit(votingCourt, "VoteCommitted")
        .withArgs(disputeId, juror1.address, voteHash, await ethers.provider.getBlock("latest").then(b => b ? b.timestamp + 1 : 0));
    });

    it("Should reject commit from non-selected juror", async function () {
      const voteHash = ethers.keccak256(ethers.toUtf8Bytes("vote"));

      await expect(
        votingCourt.connect(owner).commitVote(disputeId, voteHash)
      ).to.be.revertedWith("Not a selected juror");
    });

    it("Should reject duplicate commits", async function () {
      const voteHash = ethers.keccak256(ethers.toUtf8Bytes("vote"));

      await votingCourt.connect(juror1).commitVote(disputeId, voteHash);

      await expect(
        votingCourt.connect(juror1).commitVote(disputeId, voteHash)
      ).to.be.revertedWith("Already committed");
    });
  });

  describe("Reveal Phase", function () {
    const verdict = 1; // PlaintiffWins
    const salt = ethers.encodeBytes32String("secret");
    let voteHash;

    beforeEach(async function () {
      await votingCourt.connect(system).initializeVoting(disputeId);
      
      voteHash = ethers.keccak256(
        ethers.AbiCoder.defaultAbiCoder().encode(["uint256", "bytes32"], [verdict, salt])
      );
      
      await votingCourt.connect(juror1).commitVote(disputeId, voteHash);
    });

    it("Should not allow reveal during commit period", async function () {
      await expect(
        votingCourt.connect(juror1).revealVote(disputeId, verdict, salt)
      ).to.be.revertedWith("Commit period not ended");
    });

    it("Should allow reveal after commit period", async function () {
      await time.increase(3 * 24 * 60 * 60 + 1); // Advance 3 days

      await expect(
        votingCourt.connect(juror1).revealVote(disputeId, verdict, salt)
      )
        .to.emit(votingCourt, "VoteRevealed")
        .withArgs(disputeId, juror1.address, verdict, await ethers.provider.getBlock("latest").then(b => b ? b.timestamp + 1 : 0));
    });

    it("Should reject reveal with wrong salt", async function () {
      await time.increase(3 * 24 * 60 * 60 + 1);

      const wrongSalt = ethers.encodeBytes32String("wrong");
      await expect(
        votingCourt.connect(juror1).revealVote(disputeId, verdict, wrongSalt)
      ).to.be.revertedWith("Invalid reveal");
    });

    it("Should reject reveal after reveal period", async function () {
      await time.increase(5 * 24 * 60 * 60 + 1); // Advance past reveal period

      await expect(
        votingCourt.connect(juror1).revealVote(disputeId, verdict, salt)
      ).to.be.revertedWith("Reveal period ended");
    });
  });

  describe("Finalization", function () {
    beforeEach(async function () {
      await votingCourt.connect(system).initializeVoting(disputeId);

      // Jurors commit votes
      const plaintiffVote = ethers.keccak256(
        ethers.AbiCoder.defaultAbiCoder().encode(
          ["uint256", "bytes32"],
          [1, ethers.encodeBytes32String("salt1")]
        )
      );
      const defendantVote = ethers.keccak256(
        ethers.AbiCoder.defaultAbiCoder().encode(
          ["uint256", "bytes32"],
          [2, ethers.encodeBytes32String("salt2")]
        )
      );

      await votingCourt.connect(juror1).commitVote(disputeId, plaintiffVote);
      await votingCourt.connect(juror2).commitVote(disputeId, plaintiffVote);
      await votingCourt.connect(juror3).commitVote(disputeId, defendantVote);

      // Advance to reveal period
      await time.increase(3 * 24 * 60 * 60 + 1);

      // Reveal votes
      await votingCourt.connect(juror1).revealVote(
        disputeId,
        1,
        ethers.encodeBytes32String("salt1")
      );
      await votingCourt.connect(juror2).revealVote(
        disputeId,
        1,
        ethers.encodeBytes32String("salt1")
      );
      await votingCourt.connect(juror3).revealVote(
        disputeId,
        2,
        ethers.encodeBytes32String("salt2")
      );

      // Advance past reveal period
      await time.increase(2 * 24 * 60 * 60 + 1);
    });

    it("Should finalize voting with correct verdict", async function () {
      await expect(votingCourt.finalizeVoting(disputeId))
        .to.emit(votingCourt, "VotingFinalized")
        .withArgs(disputeId, 1, 2, 1, await ethers.provider.getBlock("latest").then(b => b ? b.timestamp + 1 : 0));

      const result = await votingCourt.getVotingResult(disputeId);
      expect(result.finalVerdict).to.equal(1); // PlaintiffWins
      expect(result.plaintiffVotes).to.equal(2);
      expect(result.defendantVotes).to.equal(1);
      expect(result.finalized).to.be.true;
    });

    it("Should not allow double finalization", async function () {
      await votingCourt.finalizeVoting(disputeId);

      await expect(
        votingCourt.finalizeVoting(disputeId)
      ).to.be.revertedWith("Already finalized");
    });
  });
});

// Mock JurySelection contract for testing
const MockJurySelectionCode = `
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MockJurySelection {
    mapping(uint256 => mapping(address => bool)) private _selected;

    function addSelectedJuror(uint256 disputeId, address juror) external {
        _selected[disputeId][juror] = true;
    }

    function isJurorSelected(uint256 disputeId, address juror) external view returns (bool) {
        return _selected[disputeId][juror];
    }
}
`;

