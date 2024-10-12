// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IEvidenceVault
 * @notice Interface for the Evidence Vault contract
 */
interface IEvidenceVault {
    struct Evidence {
        uint256 evidenceId;
        uint256 disputeId;
        address submitter;
        bytes32 evidenceHash;
        string encryptedCID;
        uint256 submittedAt;
        bool verified;
    }

    event EvidenceSubmitted(
        uint256 indexed evidenceId,
        uint256 indexed disputeId,
        address indexed submitter,
        bytes32 evidenceHash,
        uint256 timestamp
    );

    event EvidenceVerified(uint256 indexed evidenceId, bool verified);

    function submitEvidence(
        uint256 disputeId,
        bytes32 evidenceHash,
        string memory encryptedCID
    ) external returns (uint256);

    function verifyEvidence(uint256 evidenceId, bytes32 providedHash) external returns (bool);

    function getEvidence(uint256 evidenceId) external view returns (Evidence memory);

    function getDisputeEvidenceList(uint256 disputeId) external view returns (uint256[] memory);
}

