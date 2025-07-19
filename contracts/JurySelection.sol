// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import "./interfaces/IJurySelection.sol";
import "./interfaces/IJuryPool.sol";

/**
 * @title JurySelection
 * @notice Handles random jury selection using Chainlink VRF
 */
contract JurySelection is IJurySelection, AccessControl, VRFConsumerBaseV2 {
    bytes32 public constant SYSTEM_ROLE = keccak256("SYSTEM_ROLE");

    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_keyHash;
    uint64 private immutable i_subscriptionId;
    uint32 private constant CALLBACK_GAS_LIMIT = 500000;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;

    IJuryPool public juryPool;

    mapping(uint256 => uint256) private _requestIdToDisputeId;
    mapping(uint256 => address[]) private _selectedJurors;
    mapping(uint256 => mapping(address => bool)) private _isSelected;
    mapping(uint256 => uint256) private _requestedJurorCount;

    constructor(
        address vrfCoordinator,
        bytes32 keyHash,
        uint64 subscriptionId,
        address _juryPool
    ) VRFConsumerBaseV2(vrfCoordinator) {
        require(_juryPool != address(0), "Invalid jury pool address");
        
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_keyHash = keyHash;
        i_subscriptionId = subscriptionId;
        juryPool = IJuryPool(_juryPool);

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(SYSTEM_ROLE, msg.sender);
    }

    /**
     * @notice Request random juror selection for a dispute
     * @param disputeId The ID of the dispute
     * @param jurorCount Number of jurors to select
     */
    function selectJurors(
        uint256 disputeId,
        uint256 jurorCount
    ) external override onlyRole(SYSTEM_ROLE) returns (uint256) {
        require(jurorCount > 0, "Invalid juror count");
        require(_selectedJurors[disputeId].length == 0, "Jurors already selected");

        address[] memory activeJurors = juryPool.getActiveJurors();
        require(activeJurors.length >= jurorCount, "Insufficient active jurors");

        // Request random words from Chainlink VRF
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_keyHash,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            CALLBACK_GAS_LIMIT,
            uint32(jurorCount)
        );

        _requestIdToDisputeId[requestId] = disputeId;
        _requestedJurorCount[disputeId] = jurorCount;

        emit SelectionRequested(disputeId, requestId, jurorCount);

        return requestId;
    }

    /**
     * @notice Callback function used by VRF Coordinator
     * @param requestId The ID of the VRF request
     * @param randomWords The random values returned by VRF
     */
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        uint256 disputeId = _requestIdToDisputeId[requestId];
        require(disputeId != 0, "Invalid request ID");

        address[] memory activeJurors = juryPool.getActiveJurors();
        uint256 jurorCount = _requestedJurorCount[disputeId];
        
        address[] memory selected = new address[](jurorCount);
        uint256 selectedCount = 0;

        for (uint256 i = 0; i < randomWords.length && selectedCount < jurorCount; i++) {
            uint256 index = randomWords[i] % activeJurors.length;
            address juror = activeJurors[index];

            // Ensure juror is eligible and not already selected
            if (juryPool.isEligibleJuror(juror) && !_isSelected[disputeId][juror]) {
                selected[selectedCount] = juror;
                _isSelected[disputeId][juror] = true;
                selectedCount++;
            }
        }

        // Store selected jurors
        for (uint256 i = 0; i < selectedCount; i++) {
            _selectedJurors[disputeId].push(selected[i]);
        }

        emit JurorsSelected(disputeId, _selectedJurors[disputeId], block.timestamp);
    }

    /**
     * @notice Get selected jurors for a dispute
     * @param disputeId The ID of the dispute
     */
    function getSelectedJurors(uint256 disputeId) external view override returns (address[] memory) {
        return _selectedJurors[disputeId];
    }

    /**
     * @notice Check if a juror is selected for a dispute
     * @param disputeId The ID of the dispute
     * @param juror Address of the juror
     */
    function isJurorSelected(
        uint256 disputeId,
        address juror
    ) external view override returns (bool) {
        return _isSelected[disputeId][juror];
    }

    /**
     * @notice Update jury pool address
     */
    function setJuryPool(address newJuryPool) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newJuryPool != address(0), "Invalid address");
        juryPool = IJuryPool(newJuryPool);
    }

    /**
     * @notice Get selection status for a dispute
     */
    function isSelectionComplete(uint256 disputeId) external view returns (bool) {
        return _selectedJurors[disputeId].length > 0;
    }

    /**
     * @notice Get number of selected jurors for a dispute
     */
    function getSelectedJurorCount(uint256 disputeId) external view returns (uint256) {
        return _selectedJurors[disputeId].length;
    }
}

