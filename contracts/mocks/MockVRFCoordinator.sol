// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title MockVRFCoordinator
 * @notice Mock Chainlink VRF Coordinator for testing
 */
contract MockVRFCoordinator {
    uint256 private requestCounter;
    
    mapping(uint256 => address) private requestToSender;
    mapping(uint256 => uint32) private requestToNumWords;

    event RandomWordsRequested(
        uint256 indexed requestId,
        address indexed sender,
        uint32 numWords
    );

    function requestRandomWords(
        bytes32,
        uint64,
        uint16,
        uint32 callbackGasLimit,
        uint32 numWords
    ) external returns (uint256) {
        requestCounter++;
        uint256 requestId = requestCounter;
        
        requestToSender[requestId] = msg.sender;
        requestToNumWords[requestId] = numWords;

        emit RandomWordsRequested(requestId, msg.sender, numWords);
        
        return requestId;
    }

    function fulfillRandomWords(uint256 requestId, address consumer) external {
        uint32 numWords = requestToNumWords[requestId];
        uint256[] memory randomWords = new uint256[](numWords);
        
        for (uint32 i = 0; i < numWords; i++) {
            randomWords[i] = uint256(keccak256(abi.encodePacked(
                block.timestamp,
                block.prevrandao,
                requestId,
                i
            )));
        }

        (bool success,) = consumer.call(
            abi.encodeWithSignature(
                "rawFulfillRandomWords(uint256,uint256[])",
                requestId,
                randomWords
            )
        );
        require(success, "Callback failed");
    }
}

