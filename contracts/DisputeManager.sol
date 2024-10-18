// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/IDisputeManager.sol";

/**
 * @title DisputeManager
 * @notice Manages dispute creation, lifecycle, and status transitions
 */
contract DisputeManager is IDisputeManager, AccessControl, ReentrancyGuard {
    bytes32 public constant ARBITRATOR_ROLE = keccak256("ARBITRATOR_ROLE");
    bytes32 public constant SYSTEM_ROLE = keccak256("SYSTEM_ROLE");

    uint256 private _disputeCounter;
    uint256 public disputeFee;
    uint256 public evidenceSubmissionPeriod = 7 days;
    
    mapping(uint256 => DisputeInfo) private _disputes;
    mapping(address => uint256[]) private _userDisputes;

    constructor(uint256 _disputeFee) {
        disputeFee = _disputeFee;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ARBITRATOR_ROLE, msg.sender);
        _grantRole(SYSTEM_ROLE, msg.sender);
    }

    /**
     * @notice File a new dispute
     * @param defendant The address of the defendant
     * @param metadataCID IPFS CID containing dispute details
     * @param escrowContract Address of the escrow contract
     * @param escrowAmount Amount locked in escrow
     */
    function fileDispute(
        address defendant,
        string memory metadataCID,
        address escrowContract,
        uint256 escrowAmount
    ) external payable override nonReentrant returns (uint256) {
        require(msg.value >= disputeFee, "Insufficient dispute fee");
        require(defendant != address(0), "Invalid defendant address");
        require(defendant != msg.sender, "Cannot dispute with yourself");
        require(bytes(metadataCID).length > 0, "Metadata CID required");

        _disputeCounter++;
        uint256 disputeId = _disputeCounter;

        _disputes[disputeId] = DisputeInfo({
            disputeId: disputeId,
            plaintiff: msg.sender,
            defendant: defendant,
            metadataCID: metadataCID,
            escrowContract: escrowContract,
            escrowAmount: escrowAmount,
            status: DisputeStatus.Filed,
            filedAt: block.timestamp,
            deadline: block.timestamp + evidenceSubmissionPeriod
        });

        _userDisputes[msg.sender].push(disputeId);
        _userDisputes[defendant].push(disputeId);

        emit DisputeFiled(
            disputeId,
            msg.sender,
            defendant,
            metadataCID,
            block.timestamp
        );

        return disputeId;
    }

    /**
     * @notice Update dispute status
     * @param disputeId The ID of the dispute
     * @param newStatus The new status to set
     */
    function updateDisputeStatus(
        uint256 disputeId,
        DisputeStatus newStatus
    ) external override onlyRole(SYSTEM_ROLE) {
        require(_disputes[disputeId].disputeId != 0, "Dispute does not exist");
        
        DisputeStatus oldStatus = _disputes[disputeId].status;
        require(oldStatus != newStatus, "Status unchanged");
        
        _disputes[disputeId].status = newStatus;

        emit DisputeStatusChanged(disputeId, oldStatus, newStatus);
    }

    /**
     * @notice Close a dispute
     * @param disputeId The ID of the dispute
     */
    function closeDispute(uint256 disputeId) external override {
        require(_disputes[disputeId].disputeId != 0, "Dispute does not exist");
        require(
            hasRole(ARBITRATOR_ROLE, msg.sender) ||
            msg.sender == _disputes[disputeId].plaintiff ||
            msg.sender == _disputes[disputeId].defendant,
            "Unauthorized"
        );

        DisputeStatus oldStatus = _disputes[disputeId].status;
        _disputes[disputeId].status = DisputeStatus.Closed;

        emit DisputeStatusChanged(disputeId, oldStatus, DisputeStatus.Closed);
        emit DisputeClosed(disputeId, block.timestamp);
    }

    /**
     * @notice Get dispute information
     * @param disputeId The ID of the dispute
     */
    function getDisputeInfo(uint256 disputeId) external view override returns (DisputeInfo memory) {
        require(_disputes[disputeId].disputeId != 0, "Dispute does not exist");
        return _disputes[disputeId];
    }

    /**
     * @notice Get all disputes for a user
     * @param user The user address
     */
    function getUserDisputes(address user) external view returns (uint256[] memory) {
        return _userDisputes[user];
    }

    /**
     * @notice Update dispute fee
     * @param newFee The new fee amount
     */
    function setDisputeFee(uint256 newFee) external onlyRole(DEFAULT_ADMIN_ROLE) {
        disputeFee = newFee;
    }

    /**
     * @notice Update evidence submission period
     * @param newPeriod The new period in seconds
     */
    function setEvidenceSubmissionPeriod(uint256 newPeriod) external onlyRole(DEFAULT_ADMIN_ROLE) {
        evidenceSubmissionPeriod = newPeriod;
    }

    /**
     * @notice Withdraw collected fees
     */
    function withdrawFees() external onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "No fees to withdraw");
        payable(msg.sender).transfer(balance);
    }
}

