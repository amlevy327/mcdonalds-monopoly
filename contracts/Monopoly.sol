// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
//import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumberable.sol";
//import "@openzeppelin/contracts/utils/Counters.sol";
//import "hardhat/console.sol";

contract Monopoly is AccessControl, ReentrancyGuard, VRFConsumerBaseV2 {
  //using Counters for Counters.Counter;
  //Counters.Counter private _nextTokenId;

  event RequestSent(uint256 requestId, uint32 numWords);
  event RequestFulfilled(uint256 requestId, uint256 randomWord);

  bytes32 public constant MANAGER_ROLE = keccak256("MANAGER");
  
  VRFCoordinatorV2Interface public immutable COORDINATOR;
  uint32 constant CALLBACK_GAS_LIMIT = 100000;
  uint16 constant REQUEST_CONFIRMATIONS = 3;
  uint32 constant NUM_WORDS = 1;
  uint64 public immutable s_subscriptionId;
  bytes32 public immutable s_keyHash;

  uint256[] public requestIds;
  uint256 public lastRequestId;
  struct RequestStatus {
    bool fulfilled;
    bool exists;
    uint256 randomWord;
  }
  mapping(uint256 => RequestStatus) public s_requests;

  //mapping(uint256 => uint256) public tokenIdToRequest;

  constructor(
    uint64 subscriptionId,
    address vrfCoordinator,
    bytes32 keyHash
  ) VRFConsumerBaseV2(vrfCoordinator) {
    COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    s_keyHash = keyHash;
    s_subscriptionId = subscriptionId;
  }
  
  // create unrevealed game piece
  // TODO: access control
  function requestRandomWords() external returns(uint256) {
    uint256 requestId = COORDINATOR.requestRandomWords(
      s_keyHash,
      s_subscriptionId,
      REQUEST_CONFIRMATIONS,
      CALLBACK_GAS_LIMIT,
      NUM_WORDS
    );

    s_requests[requestId] = RequestStatus({
      randomWord:0,
      exists: true,
      fulfilled: false
    });
    requestIds.push(requestId);
    lastRequestId = requestId;

    emit RequestSent(requestId, NUM_WORDS);
    return requestId;
  }

  // reveal property
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
    internal
    override
  {
    require(s_requests[requestId].exists, "REQUEST_NOT_FOUND");
    s_requests[requestId].fulfilled = true;
    uint256 randomNumber = (randomWords[0] % 100) + 1;
    s_requests[requestId].randomWord = randomNumber;
    emit RequestFulfilled(requestId, randomNumber);

    // mint NFT?
  }

  // revealed?
  function getRequestStatus(
    uint256 _requestId
  ) external view returns (bool fulfilled, uint256  randomWord) {
    require(s_requests[_requestId].exists, "REQUEST_NOT_FOUND");
    RequestStatus memory request = s_requests[_requestId];
    return (request.fulfilled, request.randomWord);
  } 
}

/*

Define roles
-Admin
-Manager

Define ranges for each ticket:
MED_AVE = 1
BAL_AVE = 84
CONN_AVE = 85
VER_AVE = 90
ORI_AVE = 100

Chainlink stuff
-

Link to other contract to mint?

*/