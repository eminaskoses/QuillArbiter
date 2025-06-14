// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/IAppealBoard.sol";
import "./interfaces/IDisputeManager.sol";

/**
 * @title AppealBoard
 * @notice Manages appeal process for disputed rulings
 */
contract AppealBoard is IAppealBoard, AccessControl, ReentrancyGuard {
    bytes32 public constant ARBITRATOR_ROLE = keccak256("ARBITRATOR_ROLE");

    IDisputeManager public disputeManager;

    uint256 private _appealCounter;
    uint256 public appealFee = 0.5 ether;
    uint256 public appealPeriod = 7 days;

    mapping(uint256 => Appeal) private _appeals;
    mapping(uint256 => uint256[]) private _disputeAppeals;
    mapping(uint256 => bool) private _hasActiveAppeal;

    constructor(address _disputeManager) {
        require(_disputeManager != address(0), "Invalid dispute manager");
        disputeManager = IDisputeManager(_disputeManager);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ARBITRATOR_ROLE, msg.sender);
    }

    /**
     * @notice File an appeal for a dispute ruling
     * @param disputeId The ID of the dispute
     * @param reason The reason for the appeal
     */
    function fileAppeal(
        uint256 disputeId,
        string memory reason
    ) external payable override nonReentrant returns (uint256) {
        require(msg.value >= appealFee, "Insufficient appeal fee");
        require(bytes(reason).length > 0, "Reason required");
        require(!_hasActiveAppeal[disputeId], "Active appeal exists");

        IDisputeManager.DisputeInfo memory dispute = disputeManager.getDisputeInfo(disputeId);
        require(dispute.disputeId != 0, "Dispute does not exist");
        require(
            msg.sender == dispute.plaintiff || msg.sender == dispute.defendant,
            "Only dispute parties can appeal"
        );
        require(
            dispute.status == IDisputeManager.DisputeStatus.Executed,
            "Dispute not executed yet"
        );

        _appealCounter++;
        uint256 appealId = _appealCounter;

        _appeals[appealId] = Appeal({
            appealId: appealId,
            disputeId: disputeId,
            appellant: msg.sender,
            reason: reason,
            appealFee: msg.value,
            processed: false,
            accepted: false,
            filedAt: block.timestamp
        });

        _disputeAppeals[disputeId].push(appealId);
        _hasActiveAppeal[disputeId] = true;

        // Update dispute status to Appealed
        disputeManager.updateDisputeStatus(disputeId, IDisputeManager.DisputeStatus.Appealed);

        emit AppealFiled(appealId, disputeId, msg.sender, msg.value, block.timestamp);

        return appealId;
    }

    /**
     * @notice Process an appeal decision
     * @param appealId The ID of the appeal
     * @param accept Whether to accept or reject the appeal
     */
    function processAppeal(
        uint256 appealId,
        bool accept
    ) external override onlyRole(ARBITRATOR_ROLE) nonReentrant {
        require(_appeals[appealId].appealId != 0, "Appeal does not exist");
        require(!_appeals[appealId].processed, "Appeal already processed");

        Appeal storage appeal = _appeals[appealId];
        appeal.processed = true;
        appeal.accepted = accept;

        uint256 disputeId = appeal.disputeId;
        _hasActiveAppeal[disputeId] = false;

        if (accept) {
            // Return appeal fee if accepted
            payable(appeal.appellant).transfer(appeal.appealFee);
            
            // Reset dispute to voting stage for re-evaluation
            disputeManager.updateDisputeStatus(disputeId, IDisputeManager.DisputeStatus.Voting);
        } else {
            // Appeal fee goes to the protocol if rejected
            // Already held in contract
        }

        emit AppealProcessed(appealId, accept, block.timestamp);
    }

    /**
     * @notice Get appeal details
     * @param appealId The ID of the appeal
     */
    function getAppeal(uint256 appealId) external view override returns (Appeal memory) {
        require(_appeals[appealId].appealId != 0, "Appeal does not exist");
        return _appeals[appealId];
    }

    /**
     * @notice Get all appeals for a dispute
     * @param disputeId The ID of the dispute
     */
    function getDisputeAppeals(uint256 disputeId) external view override returns (uint256[] memory) {
        return _disputeAppeals[disputeId];
    }

    /**
     * @notice Check if a dispute has an active appeal
     * @param disputeId The ID of the dispute
     */
    function hasActiveAppeal(uint256 disputeId) external view returns (bool) {
        return _hasActiveAppeal[disputeId];
    }

    /**
     * @notice Update appeal fee
     */
    function setAppealFee(uint256 newFee) external onlyRole(DEFAULT_ADMIN_ROLE) {
        appealFee = newFee;
    }

    /**
     * @notice Update appeal period
     */
    function setAppealPeriod(uint256 newPeriod) external onlyRole(DEFAULT_ADMIN_ROLE) {
        appealPeriod = newPeriod;
    }

    /**
     * @notice Update dispute manager address
     */
    function setDisputeManager(address newDisputeManager) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newDisputeManager != address(0), "Invalid address");
        disputeManager = IDisputeManager(newDisputeManager);
    }

    /**
     * @notice Withdraw collected appeal fees
     */
    function withdrawFees() external onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "No fees to withdraw");
        payable(msg.sender).transfer(balance);
    }

    /**
     * @notice Get total appeal count
     */
    function getTotalAppeals() external view returns (uint256) {
        return _appealCounter;
    }

    /**
     * @notice Check if appeal is pending
     */
    function isAppealPending(uint256 appealId) external view returns (bool) {
        require(_appeals[appealId].appealId != 0, "Appeal does not exist");
        return !_appeals[appealId].processed;
    }
}

