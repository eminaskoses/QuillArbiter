// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Errors
 * @notice Custom errors for gas-efficient error handling
 */
library Errors {
    // DisputeManager errors
    error InsufficientDisputeFee(uint256 provided, uint256 required);
    error InvalidDefendant();
    error CannotDisputeWithSelf();
    error DisputeDoesNotExist(uint256 disputeId);
    error DisputeAlreadyClosed(uint256 disputeId);
    error Unauthorized();

    // EvidenceVault errors
    error NotDisputeParty();
    error EvidenceSubmissionEnded();
    error InvalidEvidenceHash();
    error EmptyCID();
    error EvidenceDoesNotExist(uint256 evidenceId);

    // JuryPool errors
    error InsufficientStake(uint256 provided, uint256 required);
    error NotAJuror();
    error LockPeriodNotEnded(uint256 remainingTime);
    error InsufficientStakedAmount();
    error NotEligible();

    // VotingCourt errors
    error VotingNotInitialized();
    error VotingAlreadyInitialized();
    error NotSelectedJuror();
    error AlreadyCommitted();
    error AlreadyRevealed();
    error CommitPeriodNotEnded();
    error RevealPeriodEnded();
    error InvalidReveal();
    error AlreadyFinalized();

    // RulingExecutor errors
    error RulingAlreadyExecuted();
    error VotingNotFinalized();

    // AppealBoard errors
    error InsufficientAppealFee(uint256 provided, uint256 required);
    error ActiveAppealExists();
    error AppealDoesNotExist(uint256 appealId);
    error AppealAlreadyProcessed();
}

