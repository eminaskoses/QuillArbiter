// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IJurySelection
 * @notice Interface for the Jury Selection contract with VRF-based random selection
 */
interface IJurySelection {
    event JurorsSelected(
        uint256 indexed disputeId,
        address[] jurors,
        uint256 timestamp
    );

    event SelectionRequested(
        uint256 indexed disputeId,
        uint256 requestId,
        uint256 jurorCount
    );

    function selectJurors(uint256 disputeId, uint256 jurorCount) external returns (uint256);

    function getSelectedJurors(uint256 disputeId) external view returns (address[] memory);

    function isJurorSelected(uint256 disputeId, address juror) external view returns (bool);
}

