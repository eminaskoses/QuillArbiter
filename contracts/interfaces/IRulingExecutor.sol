// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IVotingCourt.sol";

/**
 * @title IRulingExecutor
 * @notice Interface for executing final rulings and managing escrow
 */
interface IRulingExecutor {
    struct Ruling {
        uint256 disputeId;
        IVotingCourt.Verdict verdict;
        address winner;
        address loser;
        uint256 amount;
        bool executed;
        uint256 executedAt;
    }

    event RulingExecuted(
        uint256 indexed disputeId,
        IVotingCourt.Verdict verdict,
        address indexed winner,
        uint256 amount,
        uint256 timestamp
    );

    event EscrowReleased(
        uint256 indexed disputeId,
        address indexed recipient,
        uint256 amount
    );

    event PenaltyApplied(
        uint256 indexed disputeId,
        address indexed penalized,
        uint256 amount
    );

    function executeRuling(uint256 disputeId) external;

    function releaseEscrow(uint256 disputeId, address recipient, uint256 amount) external;

    function applyPenalty(uint256 disputeId, address penalized, uint256 amount) external;

    function getRuling(uint256 disputeId) external view returns (Ruling memory);
}

