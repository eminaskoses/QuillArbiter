// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/IEvidenceVault.sol";
import "./interfaces/IDisputeManager.sol";

/**
 * @title EvidenceVault
 * @notice Manages encrypted evidence storage and hash-based verification
 */
contract EvidenceVault is IEvidenceVault, AccessControl {
    bytes32 public constant VERIFIER_ROLE = keccak256("VERIFIER_ROLE");

    IDisputeManager public disputeManager;
    
    uint256 private _evidenceCounter;
    mapping(uint256 => Evidence) private _evidence;
    mapping(uint256 => uint256[]) private _disputeEvidence;
    mapping(address => uint256[]) private _submitterEvidence;

    constructor(address _disputeManager) {
        require(_disputeManager != address(0), "Invalid dispute manager");
        disputeManager = IDisputeManager(_disputeManager);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(VERIFIER_ROLE, msg.sender);
    }

    /**
     * @notice Submit evidence for a dispute
     * @param disputeId The ID of the dispute
     * @param evidenceHash Hash of the evidence for integrity verification
     * @param encryptedCID IPFS/Arweave CID of encrypted evidence
     */
    function submitEvidence(
        uint256 disputeId,
        bytes32 evidenceHash,
        string memory encryptedCID
    ) external override returns (uint256) {
        IDisputeManager.DisputeInfo memory dispute = disputeManager.getDisputeInfo(disputeId);
        require(dispute.disputeId != 0, "Dispute does not exist");
        require(
            msg.sender == dispute.plaintiff || msg.sender == dispute.defendant,
            "Only dispute parties can submit evidence"
        );
        require(
            dispute.status == IDisputeManager.DisputeStatus.Filed ||
            dispute.status == IDisputeManager.DisputeStatus.EvidenceSubmission,
            "Evidence submission period ended"
        );
        require(block.timestamp <= dispute.deadline, "Submission deadline passed");
        require(evidenceHash != bytes32(0), "Invalid evidence hash");
        require(bytes(encryptedCID).length > 0, "Encrypted CID required");

        _evidenceCounter++;
        uint256 evidenceId = _evidenceCounter;

        _evidence[evidenceId] = Evidence({
            evidenceId: evidenceId,
            disputeId: disputeId,
            submitter: msg.sender,
            evidenceHash: evidenceHash,
            encryptedCID: encryptedCID,
            submittedAt: block.timestamp,
            verified: false
        });

        _disputeEvidence[disputeId].push(evidenceId);
        _submitterEvidence[msg.sender].push(evidenceId);

        emit EvidenceSubmitted(
            evidenceId,
            disputeId,
            msg.sender,
            evidenceHash,
            block.timestamp
        );

        return evidenceId;
    }

    /**
     * @notice Verify evidence integrity by comparing hashes
     * @param evidenceId The ID of the evidence
     * @param providedHash The hash to verify against
     */
    function verifyEvidence(
        uint256 evidenceId,
        bytes32 providedHash
    ) external override onlyRole(VERIFIER_ROLE) returns (bool) {
        require(_evidence[evidenceId].evidenceId != 0, "Evidence does not exist");
        
        bool isValid = _evidence[evidenceId].evidenceHash == providedHash;
        _evidence[evidenceId].verified = isValid;

        emit EvidenceVerified(evidenceId, isValid);
        
        return isValid;
    }

    /**
     * @notice Get evidence details
     * @param evidenceId The ID of the evidence
     */
    function getEvidence(uint256 evidenceId) external view override returns (Evidence memory) {
        require(_evidence[evidenceId].evidenceId != 0, "Evidence does not exist");
        return _evidence[evidenceId];
    }

    /**
     * @notice Get all evidence IDs for a dispute
     * @param disputeId The ID of the dispute
     */
    function getDisputeEvidenceList(uint256 disputeId) external view override returns (uint256[] memory) {
        return _disputeEvidence[disputeId];
    }

    /**
     * @notice Get all evidence IDs submitted by an address
     * @param submitter The submitter address
     */
    function getSubmitterEvidenceList(address submitter) external view returns (uint256[] memory) {
        return _submitterEvidence[submitter];
    }

    /**
     * @notice Update dispute manager address
     * @param newDisputeManager The new dispute manager address
     */
    function setDisputeManager(address newDisputeManager) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newDisputeManager != address(0), "Invalid address");
        disputeManager = IDisputeManager(newDisputeManager);
    }
}

