// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title MockJurySelection
 * @notice Mock contract for testing VotingCourt
 */
contract MockJurySelection {
    mapping(uint256 => mapping(address => bool)) private _selected;

    function addSelectedJuror(uint256 disputeId, address juror) external {
        _selected[disputeId][juror] = true;
    }

    function isJurorSelected(uint256 disputeId, address juror) external view returns (bool) {
        return _selected[disputeId][juror];
    }
}

