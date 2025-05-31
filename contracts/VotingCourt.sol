// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/IVotingCourt.sol";
import "./interfaces/IJurySelection.sol";

/**
 * @title VotingCourt
 * @notice Manages commit-reveal voting process for disputes
 */
contract VotingCourt is IVotingCourt, AccessControl {
    bytes32 public constant SYSTEM_ROLE = keccak256("SYSTEM_ROLE");

    IJurySelection public jurySelection;

    uint256 public commitPeriod = 3 days;
    uint256 public revealPeriod = 2 days;

    struct VotingSession {
        uint256 disputeId;
        uint256 commitDeadline;
        uint256 revealDeadline;
        uint256 plaintiffVotes;
        uint256 defendantVotes;
        uint256 totalVotes;
        Verdict finalVerdict;
        bool finalized;
    }

    mapping(uint256 => VotingSession) private _votingSessions;
    mapping(uint256 => mapping(address => Vote)) private _votes;

    constructor(address _jurySelection) {
        require(_jurySelection != address(0), "Invalid jury selection address");
        jurySelection = IJurySelection(_jurySelection);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(SYSTEM_ROLE, msg.sender);
    }

    /**
     * @notice Initialize voting session for a dispute
     * @param disputeId The ID of the dispute
     */
    function initializeVoting(uint256 disputeId) external onlyRole(SYSTEM_ROLE) {
        require(_votingSessions[disputeId].disputeId == 0, "Voting already initialized");

        _votingSessions[disputeId] = VotingSession({
            disputeId: disputeId,
            commitDeadline: block.timestamp + commitPeriod,
            revealDeadline: block.timestamp + commitPeriod + revealPeriod,
            plaintiffVotes: 0,
            defendantVotes: 0,
            totalVotes: 0,
            finalVerdict: Verdict.Pending,
            finalized: false
        });
    }

    /**
     * @notice Commit a vote hash (commit phase)
     * @param disputeId The ID of the dispute
     * @param voteHash Hash of the vote (keccak256(verdict, salt))
     */
    function commitVote(uint256 disputeId, bytes32 voteHash) external override {
        VotingSession storage session = _votingSessions[disputeId];
        require(session.disputeId != 0, "Voting not initialized");
        require(block.timestamp <= session.commitDeadline, "Commit period ended");
        require(jurySelection.isJurorSelected(disputeId, msg.sender), "Not a selected juror");
        require(!_votes[disputeId][msg.sender].committed, "Already committed");

        _votes[disputeId][msg.sender] = Vote({
            juror: msg.sender,
            commitHash: voteHash,
            verdict: Verdict.Pending,
            committed: true,
            revealed: false,
            committedAt: block.timestamp
        });

        emit VoteCommitted(disputeId, msg.sender, voteHash, block.timestamp);
    }

    /**
     * @notice Reveal a committed vote (reveal phase)
     * @param disputeId The ID of the dispute
     * @param verdict The actual verdict
     * @param salt The salt used in the commit hash
     */
    function revealVote(
        uint256 disputeId,
        Verdict verdict,
        bytes32 salt
    ) external override {
        VotingSession storage session = _votingSessions[disputeId];
        require(session.disputeId != 0, "Voting not initialized");
        require(block.timestamp > session.commitDeadline, "Commit period not ended");
        require(block.timestamp <= session.revealDeadline, "Reveal period ended");
        
        Vote storage vote = _votes[disputeId][msg.sender];
        require(vote.committed, "Vote not committed");
        require(!vote.revealed, "Already revealed");

        // Verify the commit hash
        bytes32 computedHash = keccak256(abi.encodePacked(uint256(verdict), salt));
        require(computedHash == vote.commitHash, "Invalid reveal");

        vote.verdict = verdict;
        vote.revealed = true;

        // Update vote counts
        if (verdict == Verdict.PlaintiffWins) {
            session.plaintiffVotes++;
        } else if (verdict == Verdict.DefendantWins) {
            session.defendantVotes++;
        }
        session.totalVotes++;

        emit VoteRevealed(disputeId, msg.sender, verdict, block.timestamp);
    }

    /**
     * @notice Finalize voting and determine the verdict
     * @param disputeId The ID of the dispute
     */
    function finalizeVoting(uint256 disputeId) external override returns (Verdict) {
        VotingSession storage session = _votingSessions[disputeId];
        require(session.disputeId != 0, "Voting not initialized");
        require(block.timestamp > session.revealDeadline, "Reveal period not ended");
        require(!session.finalized, "Already finalized");

        Verdict finalVerdict;
        
        if (session.plaintiffVotes > session.defendantVotes) {
            finalVerdict = Verdict.PlaintiffWins;
        } else if (session.defendantVotes > session.plaintiffVotes) {
            finalVerdict = Verdict.DefendantWins;
        } else {
            finalVerdict = Verdict.Draw;
        }

        session.finalVerdict = finalVerdict;
        session.finalized = true;

        emit VotingFinalized(
            disputeId,
            finalVerdict,
            session.plaintiffVotes,
            session.defendantVotes,
            block.timestamp
        );

        return finalVerdict;
    }

    /**
     * @notice Get voting results for a dispute
     * @param disputeId The ID of the dispute
     */
    function getVotingResult(uint256 disputeId) external view override returns (
        Verdict finalVerdict,
        uint256 plaintiffVotes,
        uint256 defendantVotes,
        bool finalized
    ) {
        VotingSession memory session = _votingSessions[disputeId];
        return (
            session.finalVerdict,
            session.plaintiffVotes,
            session.defendantVotes,
            session.finalized
        );
    }

    /**
     * @notice Get vote details for a juror
     * @param disputeId The ID of the dispute
     * @param juror Address of the juror
     */
    function getJurorVote(uint256 disputeId, address juror) external view returns (Vote memory) {
        return _votes[disputeId][juror];
    }

    /**
     * @notice Get voting session details
     * @param disputeId The ID of the dispute
     */
    function getVotingSession(uint256 disputeId) external view returns (VotingSession memory) {
        return _votingSessions[disputeId];
    }

    /**
     * @notice Update commit period
     */
    function setCommitPeriod(uint256 period) external onlyRole(DEFAULT_ADMIN_ROLE) {
        commitPeriod = period;
    }

    /**
     * @notice Update reveal period
     */
    function setRevealPeriod(uint256 period) external onlyRole(DEFAULT_ADMIN_ROLE) {
        revealPeriod = period;
    }

    /**
     * @notice Update jury selection address
     */
    function setJurySelection(address newJurySelection) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newJurySelection != address(0), "Invalid address");
        jurySelection = IJurySelection(newJurySelection);
    }

    /**
     * @notice Check if commit period is active
     */
    function isCommitPeriodActive(uint256 disputeId) external view returns (bool) {
        VotingSession memory session = _votingSessions[disputeId];
        return session.disputeId != 0 && block.timestamp <= session.commitDeadline;
    }

    /**
     * @notice Check if reveal period is active
     */
    function isRevealPeriodActive(uint256 disputeId) external view returns (bool) {
        VotingSession memory session = _votingSessions[disputeId];
        return session.disputeId != 0 && 
               block.timestamp > session.commitDeadline &&
               block.timestamp <= session.revealDeadline;
    }
}

