// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Events
 * @notice Centralized event definitions for QuillArbiter protocol
 */
library Events {
    // DisputeManager Events
    event DisputeFiled(
        uint256 indexed disputeId,
        address indexed plaintiff,
        address indexed defendant,
        string metadataCID,
        uint256 timestamp
    );

    event DisputeStatusChanged(
        uint256 indexed disputeId,
        uint8 oldStatus,
        uint8 newStatus
    );

    event DisputeClosed(
        uint256 indexed disputeId,
        uint256 timestamp
    );

    // EvidenceVault Events
    event EvidenceSubmitted(
        uint256 indexed evidenceId,
        uint256 indexed disputeId,
        address indexed submitter,
        bytes32 evidenceHash,
        uint256 timestamp
    );

    event EvidenceVerified(
        uint256 indexed evidenceId,
        bool verified
    );

    // JuryPool Events
    event JurorStaked(
        address indexed juror,
        uint256 amount,
        uint256 totalStaked,
        uint256 timestamp
    );

    event JurorWithdrawn(
        address indexed juror,
        uint256 amount,
        uint256 remainingStake,
        uint256 timestamp
    );

    event JurorSlashed(
        address indexed juror,
        uint256 amount,
        uint256 remainingStake,
        uint256 timestamp
    );

    event ReputationUpdated(
        address indexed juror,
        uint256 oldReputation,
        uint256 newReputation
    );
}

