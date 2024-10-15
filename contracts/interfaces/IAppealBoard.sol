// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IAppealBoard
 * @notice Interface for the Appeal Board contract
 */
interface IAppealBoard {
    struct Appeal {
        uint256 appealId;
        uint256 disputeId;
        address appellant;
        string reason;
        uint256 appealFee;
        bool processed;
        bool accepted;
        uint256 filedAt;
    }

    event AppealFiled(
        uint256 indexed appealId,
        uint256 indexed disputeId,
        address indexed appellant,
        uint256 fee,
        uint256 timestamp
    );

    event AppealProcessed(
        uint256 indexed appealId,
        bool accepted,
        uint256 timestamp
    );

    function fileAppeal(uint256 disputeId, string memory reason) external payable returns (uint256);

    function processAppeal(uint256 appealId, bool accept) external;

    function getAppeal(uint256 appealId) external view returns (Appeal memory);

    function getDisputeAppeals(uint256 disputeId) external view returns (uint256[] memory);
}

