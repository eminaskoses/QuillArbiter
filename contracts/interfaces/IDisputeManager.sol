// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IDisputeManager
 * @notice Interface for the Dispute Manager contract
 */
interface IDisputeManager {
    enum DisputeStatus {
        Filed,
        EvidenceSubmission,
        JurySelection,
        Voting,
        Ruling,
        Executed,
        Appealed,
        Closed
    }

    struct DisputeInfo {
        uint256 disputeId;
        address plaintiff;
        address defendant;
        string metadataCID;
        address escrowContract;
        uint256 escrowAmount;
        DisputeStatus status;
        uint256 filedAt;
        uint256 deadline;
    }

    event DisputeFiled(
        uint256 indexed disputeId,
        address indexed plaintiff,
        address indexed defendant,
        string metadataCID,
        uint256 timestamp
    );

    event DisputeStatusChanged(
        uint256 indexed disputeId,
        DisputeStatus oldStatus,
        DisputeStatus newStatus
    );

    event DisputeClosed(uint256 indexed disputeId, uint256 timestamp);

    function fileDispute(
        address defendant,
        string memory metadataCID,
        address escrowContract,
        uint256 escrowAmount
    ) external payable returns (uint256);

    function updateDisputeStatus(uint256 disputeId, DisputeStatus newStatus) external;

    function closeDispute(uint256 disputeId) external;

    function getDisputeInfo(uint256 disputeId) external view returns (DisputeInfo memory);
}

