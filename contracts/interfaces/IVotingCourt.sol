// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IVotingCourt
 * @notice Interface for the Voting Court contract with commit-reveal voting
 */
interface IVotingCourt {
    enum Verdict {
        Pending,
        PlaintiffWins,
        DefendantWins,
        Draw
    }

    struct Vote {
        address juror;
        bytes32 commitHash;
        Verdict verdict;
        bool committed;
        bool revealed;
        uint256 committedAt;
    }

    event VoteCommitted(
        uint256 indexed disputeId,
        address indexed juror,
        bytes32 commitHash,
        uint256 timestamp
    );

    event VoteRevealed(
        uint256 indexed disputeId,
        address indexed juror,
        Verdict verdict,
        uint256 timestamp
    );

    event VotingFinalized(
        uint256 indexed disputeId,
        Verdict finalVerdict,
        uint256 plaintiffVotes,
        uint256 defendantVotes,
        uint256 timestamp
    );

    function commitVote(uint256 disputeId, bytes32 voteHash) external;

    function revealVote(uint256 disputeId, Verdict verdict, bytes32 salt) external;

    function finalizeVoting(uint256 disputeId) external returns (Verdict);

    function getVotingResult(uint256 disputeId) external view returns (
        Verdict finalVerdict,
        uint256 plaintiffVotes,
        uint256 defendantVotes,
        bool finalized
    );
}

