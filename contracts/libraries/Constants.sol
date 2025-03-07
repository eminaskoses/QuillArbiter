// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Constants
 * @notice Global constants used across QuillArbiter contracts
 */
library Constants {
    // Role identifiers
    bytes32 public constant SYSTEM_ROLE = keccak256("SYSTEM_ROLE");
    bytes32 public constant ARBITRATOR_ROLE = keccak256("ARBITRATOR_ROLE");
    bytes32 public constant VERIFIER_ROLE = keccak256("VERIFIER_ROLE");

    // Time periods (in seconds)
    uint256 public constant DEFAULT_EVIDENCE_PERIOD = 7 days;
    uint256 public constant DEFAULT_COMMIT_PERIOD = 3 days;
    uint256 public constant DEFAULT_REVEAL_PERIOD = 2 days;
    uint256 public constant DEFAULT_LOCK_PERIOD = 30 days;
    uint256 public constant DEFAULT_APPEAL_PERIOD = 7 days;

    // Stake and fee amounts (in wei)
    uint256 public constant MIN_STAKE_AMOUNT = 0.1 ether;
    uint256 public constant DEFAULT_DISPUTE_FEE = 0.01 ether;
    uint256 public constant DEFAULT_APPEAL_FEE = 0.5 ether;

    // Reputation parameters
    uint256 public constant INITIAL_REPUTATION = 100;
    uint256 public constant MIN_REPUTATION_SCORE = 50;
    uint256 public constant MAX_REPUTATION = 1000;
    uint256 public constant REPUTATION_INCREASE = 105; // 5% increase
    uint256 public constant REPUTATION_DECREASE = 90; // 10% decrease

    // Voting parameters
    uint256 public constant MIN_JUROR_COUNT = 3;
    uint256 public constant MAX_JUROR_COUNT = 21;
    uint256 public constant DEFAULT_JUROR_COUNT = 7;

    // VRF parameters
    uint32 public constant VRF_CALLBACK_GAS_LIMIT = 500000;
    uint16 public constant VRF_REQUEST_CONFIRMATIONS = 3;
}

