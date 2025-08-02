// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/IRulingExecutor.sol";
import "./interfaces/IVotingCourt.sol";
import "./interfaces/IDisputeManager.sol";
import "./interfaces/IJuryPool.sol";

/**
 * @title RulingExecutor
 * @notice Executes final rulings and manages escrow distribution
 */
contract RulingExecutor is IRulingExecutor, AccessControl, ReentrancyGuard {
    bytes32 public constant SYSTEM_ROLE = keccak256("SYSTEM_ROLE");

    IDisputeManager public disputeManager;
    IVotingCourt public votingCourt;
    IJuryPool public juryPool;

    mapping(uint256 => Ruling) private _rulings;
    mapping(uint256 => bool) private _executed;

    constructor(
        address _disputeManager,
        address _votingCourt,
        address _juryPool
    ) {
        require(_disputeManager != address(0), "Invalid dispute manager");
        require(_votingCourt != address(0), "Invalid voting court");
        require(_juryPool != address(0), "Invalid jury pool");

        disputeManager = IDisputeManager(_disputeManager);
        votingCourt = IVotingCourt(_votingCourt);
        juryPool = IJuryPool(_juryPool);

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(SYSTEM_ROLE, msg.sender);
    }

    /**
     * @notice Execute ruling based on voting results
     * @param disputeId The ID of the dispute
     */
    function executeRuling(uint256 disputeId) external override nonReentrant {
        require(!_executed[disputeId], "Ruling already executed");

        IDisputeManager.DisputeInfo memory dispute = disputeManager.getDisputeInfo(disputeId);
        require(dispute.disputeId != 0, "Dispute does not exist");

        (
            IVotingCourt.Verdict verdict,
            uint256 plaintiffVotes,
            uint256 defendantVotes,
            bool finalized
        ) = votingCourt.getVotingResult(disputeId);

        require(finalized, "Voting not finalized");

        address winner;
        address loser;

        if (verdict == IVotingCourt.Verdict.PlaintiffWins) {
            winner = dispute.plaintiff;
            loser = dispute.defendant;
        } else if (verdict == IVotingCourt.Verdict.DefendantWins) {
            winner = dispute.defendant;
            loser = dispute.plaintiff;
        } else {
            // Draw - split or return funds
            winner = address(0);
            loser = address(0);
        }

        _rulings[disputeId] = Ruling({
            disputeId: disputeId,
            verdict: verdict,
            winner: winner,
            loser: loser,
            amount: dispute.escrowAmount,
            executed: true,
            executedAt: block.timestamp
        });

        _executed[disputeId] = true;

        // Update dispute status
        disputeManager.updateDisputeStatus(disputeId, IDisputeManager.DisputeStatus.Executed);

        // Update juror reputations based on majority verdict
        _updateJurorReputations(disputeId, verdict, plaintiffVotes > defendantVotes);

        emit RulingExecuted(disputeId, verdict, winner, dispute.escrowAmount, block.timestamp);

        // Release escrow if applicable
        if (winner != address(0) && dispute.escrowAmount > 0) {
            _releaseEscrow(disputeId, winner, dispute.escrowAmount);
        }
    }

    /**
     * @notice Release escrow to recipient
     * @param disputeId The ID of the dispute
     * @param recipient The recipient address
     * @param amount The amount to release
     */
    function releaseEscrow(
        uint256 disputeId,
        address recipient,
        uint256 amount
    ) external override onlyRole(SYSTEM_ROLE) nonReentrant {
        _releaseEscrow(disputeId, recipient, amount);
    }

    /**
     * @notice Internal function to release escrow
     */
    function _releaseEscrow(
        uint256 disputeId,
        address recipient,
        uint256 amount
    ) private {
        require(recipient != address(0), "Invalid recipient");
        require(amount > 0, "Invalid amount");

        // In a real implementation, this would interact with the escrow contract
        // For now, we just emit the event
        emit EscrowReleased(disputeId, recipient, amount);
    }

    /**
     * @notice Apply penalty to a party
     * @param disputeId The ID of the dispute
     * @param penalized The address to penalize
     * @param amount The penalty amount
     */
    function applyPenalty(
        uint256 disputeId,
        address penalized,
        uint256 amount
    ) external override onlyRole(SYSTEM_ROLE) {
        require(penalized != address(0), "Invalid address");
        require(amount > 0, "Invalid amount");

        emit PenaltyApplied(disputeId, penalized, amount);
    }

    /**
     * @notice Update juror reputations based on voting correctness
     */
    function _updateJurorReputations(
        uint256 disputeId,
        IVotingCourt.Verdict correctVerdict,
        bool plaintiffMajority
    ) private {
        // This would iterate through all jurors and update their reputations
        // Implementation depends on access to juror votes from VotingCourt
        // Simplified version - would need more integration in production
    }

    /**
     * @notice Get ruling details
     * @param disputeId The ID of the dispute
     */
    function getRuling(uint256 disputeId) external view override returns (Ruling memory) {
        require(_executed[disputeId], "Ruling not executed");
        return _rulings[disputeId];
    }

    /**
     * @notice Check if ruling has been executed
     * @param disputeId The ID of the dispute
     */
    function isRulingExecuted(uint256 disputeId) external view returns (bool) {
        return _executed[disputeId];
    }

    /**
     * @notice Update dispute manager address
     */
    function setDisputeManager(address newDisputeManager) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newDisputeManager != address(0), "Invalid address");
        disputeManager = IDisputeManager(newDisputeManager);
    }

    /**
     * @notice Update voting court address
     */
    function setVotingCourt(address newVotingCourt) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newVotingCourt != address(0), "Invalid address");
        votingCourt = IVotingCourt(newVotingCourt);
    }

    /**
     * @notice Update jury pool address
     */
    function setJuryPool(address newJuryPool) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newJuryPool != address(0), "Invalid address");
        juryPool = IJuryPool(newJuryPool);
    }

    /**
     * @notice Get winner of a ruling
     */
    function getRulingWinner(uint256 disputeId) external view returns (address) {
        require(_executed[disputeId], "Ruling not executed");
        return _rulings[disputeId].winner;
    }
}

