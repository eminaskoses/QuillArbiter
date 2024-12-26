// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IDisputeManager.sol";

/**
 * @title DisputeFactory
 * @notice Factory contract for creating disputes with predefined templates
 */
contract DisputeFactory is Ownable {
    IDisputeManager public disputeManager;

    struct DisputeTemplate {
        string name;
        string metadataTemplate;
        uint256 recommendedEscrow;
        bool isActive;
    }

    mapping(uint256 => DisputeTemplate) public templates;
    uint256 public templateCount;

    event TemplateCreated(uint256 indexed templateId, string name);
    event TemplateUpdated(uint256 indexed templateId, bool isActive);
    event DisputeCreatedFromTemplate(
        uint256 indexed disputeId,
        uint256 indexed templateId,
        address plaintiff,
        address defendant
    );

    constructor(address _disputeManager) Ownable(msg.sender) {
        require(_disputeManager != address(0), "Invalid dispute manager");
        disputeManager = IDisputeManager(_disputeManager);
    }

    /**
     * @notice Create a new dispute template
     */
    function createTemplate(
        string memory name,
        string memory metadataTemplate,
        uint256 recommendedEscrow
    ) external onlyOwner returns (uint256) {
        templateCount++;
        uint256 templateId = templateCount;

        templates[templateId] = DisputeTemplate({
            name: name,
            metadataTemplate: metadataTemplate,
            recommendedEscrow: recommendedEscrow,
            isActive: true
        });

        emit TemplateCreated(templateId, name);
        return templateId;
    }

    /**
     * @notice Create a dispute from a template
     */
    function createDisputeFromTemplate(
        uint256 templateId,
        address defendant,
        string memory specificMetadata,
        address escrowContract
    ) external payable returns (uint256) {
        require(templates[templateId].isActive, "Template not active");

        uint256 disputeId = disputeManager.fileDispute{value: msg.value}(
            defendant,
            specificMetadata,
            escrowContract,
            templates[templateId].recommendedEscrow
        );

        emit DisputeCreatedFromTemplate(disputeId, templateId, msg.sender, defendant);
        return disputeId;
    }

    /**
     * @notice Update template status
     */
    function updateTemplateStatus(uint256 templateId, bool isActive) external onlyOwner {
        require(templateId > 0 && templateId <= templateCount, "Invalid template");
        templates[templateId].isActive = isActive;
        emit TemplateUpdated(templateId, isActive);
    }

    /**
     * @notice Update dispute manager address
     */
    function setDisputeManager(address newDisputeManager) external onlyOwner {
        require(newDisputeManager != address(0), "Invalid address");
        disputeManager = IDisputeManager(newDisputeManager);
    }
}

