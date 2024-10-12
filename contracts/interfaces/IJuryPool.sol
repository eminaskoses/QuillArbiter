// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IJuryPool
 * @notice Interface for the Jury Pool contract
 */
interface IJuryPool {
    struct Juror {
        address jurorAddress;
        uint256 stakedAmount;
        uint256 reputation;
        bool isActive;
        uint256 totalVotes;
        uint256 correctVotes;
        uint256 stakedAt;
    }

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

    function stake() external payable;

    function withdraw(uint256 amount) external;

    function slash(address juror, uint256 amount) external;

    function updateReputation(address juror, bool correctVote) external;

    function getJuror(address juror) external view returns (Juror memory);

    function isEligibleJuror(address juror) external view returns (bool);

    function getActiveJurors() external view returns (address[] memory);
}

