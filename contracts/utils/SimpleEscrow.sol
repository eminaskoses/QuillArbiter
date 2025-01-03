// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../interfaces/IRulingExecutor.sol";

/**
 * @title SimpleEscrow
 * @notice Simple escrow contract for dispute resolution
 */
contract SimpleEscrow is ReentrancyGuard {
    address public immutable disputeManager;
    address public immutable rulingExecutor;

    struct EscrowDeposit {
        uint256 escrowId;
        address depositor;
        address beneficiary;
        uint256 amount;
        uint256 disputeId;
        bool released;
        bool refunded;
        uint256 createdAt;
    }

    uint256 private _escrowCounter;
    mapping(uint256 => EscrowDeposit) public escrows;
    mapping(uint256 => uint256) public disputeToEscrow;

    event EscrowCreated(
        uint256 indexed escrowId,
        address indexed depositor,
        address indexed beneficiary,
        uint256 amount
    );

    event EscrowReleased(
        uint256 indexed escrowId,
        address indexed recipient,
        uint256 amount
    );

    event EscrowRefunded(
        uint256 indexed escrowId,
        address indexed depositor,
        uint256 amount
    );

    event EscrowLinkedToDispute(
        uint256 indexed escrowId,
        uint256 indexed disputeId
    );

    modifier onlyRulingExecutor() {
        require(msg.sender == rulingExecutor, "Only ruling executor");
        _;
    }

    constructor(address _disputeManager, address _rulingExecutor) {
        require(_disputeManager != address(0), "Invalid dispute manager");
        require(_rulingExecutor != address(0), "Invalid ruling executor");
        disputeManager = _disputeManager;
        rulingExecutor = _rulingExecutor;
    }

    /**
     * @notice Create an escrow deposit
     */
    function createEscrow(address beneficiary) external payable returns (uint256) {
        require(msg.value > 0, "Must deposit funds");
        require(beneficiary != address(0), "Invalid beneficiary");
        require(beneficiary != msg.sender, "Cannot be self");

        _escrowCounter++;
        uint256 escrowId = _escrowCounter;

        escrows[escrowId] = EscrowDeposit({
            escrowId: escrowId,
            depositor: msg.sender,
            beneficiary: beneficiary,
            amount: msg.value,
            disputeId: 0,
            released: false,
            refunded: false,
            createdAt: block.timestamp
        });

        emit EscrowCreated(escrowId, msg.sender, beneficiary, msg.value);
        return escrowId;
    }

    /**
     * @notice Link escrow to a dispute
     */
    function linkToDispute(uint256 escrowId, uint256 disputeId) external {
        require(escrows[escrowId].escrowId != 0, "Escrow does not exist");
        require(
            msg.sender == escrows[escrowId].depositor ||
            msg.sender == escrows[escrowId].beneficiary,
            "Not authorized"
        );
        require(escrows[escrowId].disputeId == 0, "Already linked");
        require(!escrows[escrowId].released && !escrows[escrowId].refunded, "Already processed");

        escrows[escrowId].disputeId = disputeId;
        disputeToEscrow[disputeId] = escrowId;

        emit EscrowLinkedToDispute(escrowId, disputeId);
    }

    /**
     * @notice Release escrow to beneficiary (called by ruling executor or parties)
     */
    function releaseEscrow(uint256 escrowId) external nonReentrant {
        EscrowDeposit storage escrow = escrows[escrowId];
        require(escrow.escrowId != 0, "Escrow does not exist");
        require(!escrow.released && !escrow.refunded, "Already processed");

        bool authorized = msg.sender == rulingExecutor ||
                         msg.sender == escrow.depositor ||
                         msg.sender == escrow.beneficiary;
        require(authorized, "Not authorized");

        escrow.released = true;
        payable(escrow.beneficiary).transfer(escrow.amount);

        emit EscrowReleased(escrowId, escrow.beneficiary, escrow.amount);
    }

    /**
     * @notice Refund escrow to depositor
     */
    function refundEscrow(uint256 escrowId) external nonReentrant {
        EscrowDeposit storage escrow = escrows[escrowId];
        require(escrow.escrowId != 0, "Escrow does not exist");
        require(!escrow.released && !escrow.refunded, "Already processed");

        bool authorized = msg.sender == rulingExecutor ||
                         msg.sender == escrow.depositor;
        require(authorized, "Not authorized");

        escrow.refunded = true;
        payable(escrow.depositor).transfer(escrow.amount);

        emit EscrowRefunded(escrowId, escrow.depositor, escrow.amount);
    }

    /**
     * @notice Execute escrow based on ruling
     */
    function executeRuling(uint256 escrowId, address winner) external onlyRulingExecutor nonReentrant {
        EscrowDeposit storage escrow = escrows[escrowId];
        require(escrow.escrowId != 0, "Escrow does not exist");
        require(!escrow.released && !escrow.refunded, "Already processed");

        if (winner == escrow.beneficiary) {
            escrow.released = true;
            payable(escrow.beneficiary).transfer(escrow.amount);
            emit EscrowReleased(escrowId, escrow.beneficiary, escrow.amount);
        } else if (winner == escrow.depositor) {
            escrow.refunded = true;
            payable(escrow.depositor).transfer(escrow.amount);
            emit EscrowRefunded(escrowId, escrow.depositor, escrow.amount);
        } else {
            // Split in case of draw
            uint256 halfAmount = escrow.amount / 2;
            escrow.released = true;
            payable(escrow.beneficiary).transfer(halfAmount);
            payable(escrow.depositor).transfer(escrow.amount - halfAmount);
            emit EscrowReleased(escrowId, escrow.beneficiary, halfAmount);
            emit EscrowRefunded(escrowId, escrow.depositor, escrow.amount - halfAmount);
        }
    }

    /**
     * @notice Get escrow details
     */
    function getEscrow(uint256 escrowId) external view returns (EscrowDeposit memory) {
        require(escrows[escrowId].escrowId != 0, "Escrow does not exist");
        return escrows[escrowId];
    }
}

