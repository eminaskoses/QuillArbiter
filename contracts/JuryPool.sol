// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/IJuryPool.sol";

/**
 * @title JuryPool
 * @notice Manages juror staking, reputation, and eligibility
 */
contract JuryPool is IJuryPool, AccessControl, ReentrancyGuard {
    bytes32 public constant SYSTEM_ROLE = keccak256("SYSTEM_ROLE");

    uint256 public minStakeAmount = 0.1 ether;
    uint256 public minReputationScore = 50;
    uint256 public lockPeriod = 30 days;

    mapping(address => Juror) private _jurors;
    address[] private _activeJurors;
    mapping(address => uint256) private _activeJurorIndex;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(SYSTEM_ROLE, msg.sender);
    }

    /**
     * @notice Stake tokens to become a juror
     */
    function stake() external payable override nonReentrant {
        require(msg.value >= minStakeAmount, "Insufficient stake amount");

        Juror storage juror = _jurors[msg.sender];
        
        if (juror.jurorAddress == address(0)) {
            // New juror
            juror.jurorAddress = msg.sender;
            juror.stakedAmount = msg.value;
            juror.reputation = 100; // Initial reputation
            juror.isActive = true;
            juror.totalVotes = 0;
            juror.correctVotes = 0;
            juror.stakedAt = block.timestamp;

            _activeJurors.push(msg.sender);
            _activeJurorIndex[msg.sender] = _activeJurors.length - 1;
        } else {
            // Existing juror adding stake
            juror.stakedAmount += msg.value;
            if (!juror.isActive && juror.stakedAmount >= minStakeAmount) {
                juror.isActive = true;
                _activeJurors.push(msg.sender);
                _activeJurorIndex[msg.sender] = _activeJurors.length - 1;
            }
        }

        emit JurorStaked(
            msg.sender,
            msg.value,
            juror.stakedAmount,
            block.timestamp
        );
    }

    /**
     * @notice Withdraw staked tokens
     * @param amount Amount to withdraw
     */
    function withdraw(uint256 amount) external override nonReentrant {
        Juror storage juror = _jurors[msg.sender];
        require(juror.jurorAddress != address(0), "Not a juror");
        require(juror.stakedAmount >= amount, "Insufficient staked amount");
        require(
            block.timestamp >= juror.stakedAt + lockPeriod,
            "Lock period not ended"
        );

        juror.stakedAmount -= amount;

        if (juror.stakedAmount < minStakeAmount && juror.isActive) {
            juror.isActive = false;
            _removeFromActiveJurors(msg.sender);
        }

        payable(msg.sender).transfer(amount);

        emit JurorWithdrawn(
            msg.sender,
            amount,
            juror.stakedAmount,
            block.timestamp
        );
    }

    /**
     * @notice Slash a juror's stake for misconduct
     * @param juror Address of the juror
     * @param amount Amount to slash
     */
    function slash(address juror, uint256 amount) external override onlyRole(SYSTEM_ROLE) {
        Juror storage jurorData = _jurors[juror];
        require(jurorData.jurorAddress != address(0), "Not a juror");
        require(jurorData.stakedAmount >= amount, "Insufficient stake");

        jurorData.stakedAmount -= amount;

        if (jurorData.stakedAmount < minStakeAmount && jurorData.isActive) {
            jurorData.isActive = false;
            _removeFromActiveJurors(juror);
        }

        emit JurorSlashed(
            juror,
            amount,
            jurorData.stakedAmount,
            block.timestamp
        );
    }

    /**
     * @notice Update juror's reputation based on voting correctness
     * @param juror Address of the juror
     * @param correctVote Whether the vote was correct
     */
    function updateReputation(
        address juror,
        bool correctVote
    ) external override onlyRole(SYSTEM_ROLE) {
        Juror storage jurorData = _jurors[juror];
        require(jurorData.jurorAddress != address(0), "Not a juror");

        uint256 oldReputation = jurorData.reputation;
        jurorData.totalVotes++;

        if (correctVote) {
            jurorData.correctVotes++;
            jurorData.reputation = jurorData.reputation * 105 / 100; // +5%
            if (jurorData.reputation > 1000) {
                jurorData.reputation = 1000; // Cap at 1000
            }
        } else {
            if (jurorData.reputation > 10) {
                jurorData.reputation = jurorData.reputation * 90 / 100; // -10%
            }
        }

        emit ReputationUpdated(juror, oldReputation, jurorData.reputation);
    }

    /**
     * @notice Get juror information
     * @param juror Address of the juror
     */
    function getJuror(address juror) external view override returns (Juror memory) {
        return _jurors[juror];
    }

    /**
     * @notice Check if an address is an eligible juror
     * @param juror Address to check
     */
    function isEligibleJuror(address juror) external view override returns (bool) {
        Juror memory jurorData = _jurors[juror];
        return jurorData.isActive &&
               jurorData.stakedAmount >= minStakeAmount &&
               jurorData.reputation >= minReputationScore;
    }

    /**
     * @notice Get list of all active jurors
     */
    function getActiveJurors() external view override returns (address[] memory) {
        return _activeJurors;
    }

    /**
     * @notice Remove juror from active list
     * @param juror Address of the juror
     */
    function _removeFromActiveJurors(address juror) private {
        uint256 index = _activeJurorIndex[juror];
        uint256 lastIndex = _activeJurors.length - 1;

        if (index != lastIndex) {
            address lastJuror = _activeJurors[lastIndex];
            _activeJurors[index] = lastJuror;
            _activeJurorIndex[lastJuror] = index;
        }

        _activeJurors.pop();
        delete _activeJurorIndex[juror];
    }

    /**
     * @notice Update minimum stake amount
     */
    function setMinStakeAmount(uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        minStakeAmount = amount;
    }

    /**
     * @notice Update minimum reputation score
     */
    function setMinReputationScore(uint256 score) external onlyRole(DEFAULT_ADMIN_ROLE) {
        minReputationScore = score;
    }

    /**
     * @notice Update lock period
     */
    function setLockPeriod(uint256 period) external onlyRole(DEFAULT_ADMIN_ROLE) {
        lockPeriod = period;
    }

    /**
     * @notice Get total number of jurors
     */
    function getTotalJurors() external view returns (uint256) {
        return _activeJurors.length;
    }

    /**
     * @notice Get juror performance metrics
     */
    function getJurorPerformance(address juror) external view returns (
        uint256 totalVotes,
        uint256 correctVotes,
        uint256 accuracy
    ) {
        Juror memory jurorData = _jurors[juror];
        uint256 accuracyPercent = jurorData.totalVotes > 0 
            ? (jurorData.correctVotes * 100) / jurorData.totalVotes 
            : 0;
        return (jurorData.totalVotes, jurorData.correctVotes, accuracyPercent);
    }
}

