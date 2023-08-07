// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./Prizes.sol";

contract GamePieces is ERC721Enumerable, ReentrancyGuard, VRFConsumerBaseV2  {
  using Counters for Counters.Counter;
  
  // *** probability constants ***
  // total range
  uint256 constant MIN = 1;
  uint256 constant MAX = 5;
  // set - brown
  uint256 constant MED_AVE = 1;
  uint256 constant BAL_AVE = 2;
  // set - light blue
  uint256 constant CONN_AVE = 3;
  uint256 constant VER_AVE = 4;
  uint256 constant ORI_AVE = 5;
  
  // *** chainlink ***
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
    uint256 tokenId;
    address account;
  }
  mapping(uint256 => RequestStatus) public s_requests;
  
  // *** NFT - game pieces ***
  Counters.Counter private _nextTokenId;
  mapping(uint256 => uint256) public tokenIdToRequest;
  mapping(address => mapping(string => uint256)) public accountToPropertyCount;

  // *** events ***
  event RequestSent(uint256 requestId, uint32 numWords, address indexed account, uint256 tokenId);
  event RequestFulfilled(uint256 requestId, uint256 randomWord, address indexed account, uint256 tokenId);

  // *** prizes ***
  Prizes public immutable PRIZES;

  constructor(
    uint64 subscriptionId,
    address vrfCoordinator,
    bytes32 keyHash,
    address prizes
  ) ERC721("McDonaldsMonopoly", "MM") 
    VRFConsumerBaseV2(vrfCoordinator) {
    // chainlink
    COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    s_keyHash = keyHash;
    s_subscriptionId = subscriptionId;
    // prizes
    PRIZES = Prizes(prizes);
    // start at token id = 1
    _nextTokenId.increment();
  }

  // Chainlink - create random word request
  // Create NFT game piece
  // NOTE: In production, add access control role
  function requestRandomWords(address account_) external nonReentrant returns(uint256) {
    uint256 requestId = COORDINATOR.requestRandomWords(
      s_keyHash,
      s_subscriptionId,
      REQUEST_CONFIRMATIONS,
      CALLBACK_GAS_LIMIT,
      NUM_WORDS
    );

    // mint NFT game pieces
    uint256 tokenId = _nextTokenId.current();
    _mint(account_, tokenId);
    tokenIdToRequest[tokenId] = requestId;

    // chainlink request
    s_requests[requestId] = RequestStatus({
      randomWord: 0,
      exists: true,
      fulfilled: false,
      account: account_,
      tokenId: tokenId
    });
    requestIds.push(requestId);
    lastRequestId = requestId;

    // event
    emit RequestSent(requestId, NUM_WORDS, account_, tokenId);

    // increment to next token id
    _nextTokenId.increment();

    return requestId;
  }

  // Chainlink - fulfill random word request
  // Reveal NFT game piece
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
    internal
    override
  {
    require(s_requests[requestId].exists, "REQUEST_NOT_FOUND");
    s_requests[requestId].fulfilled = true;
    // mod random word into set range
    uint256 randomNumber = (randomWords[0] % MAX) + MIN;
    address account = s_requests[requestId].account;
    uint256 tokenId = s_requests[requestId].tokenId;
    s_requests[requestId].randomWord = randomNumber;

    // update property count mappings
    updatePropertyCount(account, randomNumber);

    //event
    emit RequestFulfilled(requestId, randomNumber, account, tokenId);
  }

  function updatePropertyCount(address account_, uint256 randomNumber_) internal {
    if (randomNumber_ <= MED_AVE) {
      accountToPropertyCount[account_]['MED_AVE'] += 1;
    } else if (randomNumber_ > MED_AVE && randomNumber_ <= BAL_AVE) {
      accountToPropertyCount[account_]['BAL_AVE'] += 1;
    } else if (randomNumber_ > BAL_AVE && randomNumber_ <= CONN_AVE) {
      accountToPropertyCount[account_]['CONN_AVE'] += 1;
    } else if (randomNumber_ > CONN_AVE && randomNumber_ <= VER_AVE) {
      accountToPropertyCount[account_]['VER_AVE'] += 1;
    } else if (randomNumber_ > VER_AVE && randomNumber_ <= ORI_AVE) {
      accountToPropertyCount[account_]['ORI_AVE'] += 1;
    }
  }

  // Get chainlink request status
  function getRequestStatus(
    uint256 _requestId
  ) external view returns (bool fulfilled, uint256  randomWord) {
    require(s_requests[_requestId].exists, "REQUEST_NOT_FOUND");
    RequestStatus memory request = s_requests[_requestId];
    return (request.fulfilled, request.randomWord);
  }

  // Brown Set: claim prize - calls Prize contract
  // Mint and burn implementation
  // NOTE: In production, maybe add access control role based on implementation
  function claimBrownSet(address account_) public nonReentrant {
    require(accountToPropertyCount[account_]['MED_AVE'] > 0, 'NO_MED_AVE');
    require(accountToPropertyCount[account_]['BAL_AVE'] > 0, 'NO_BAL_AVE');
    
    bool med_ave = false;
    bool bal_ave = false;
    uint256 tokenId;

    for (uint256 index = balanceOf(account_) - 1; index >= 0 ; index--) {
      tokenId = tokenOfOwnerByIndex(account_, index);
      
      if (med_ave == false && s_requests[tokenIdToRequest[tokenId]].randomWord <= MED_AVE) {
        // burn property and update count
        _burn(tokenId);
        med_ave = true;
        accountToPropertyCount[account_]['MED_AVE'] -= 1;
      } else if (bal_ave == false && s_requests[tokenIdToRequest[tokenId]].randomWord > MED_AVE && s_requests[tokenIdToRequest[tokenId]].randomWord <= BAL_AVE) {
        // burn property and update count
        _burn(tokenId);
        bal_ave = true;
        accountToPropertyCount[account_]['BAL_AVE'] -= 1;
      } else if (med_ave == true && bal_ave == true) {
        // mint prize NFT
        PRIZES.mintBrown(account_);
        return;
      }
    }
  }

  // Light Blue Set: claim prize - calls Prize contract
  // Mint and burn implementation
  // NOTE: In production, maybe add access control role based on implementation
  function claimLightBlueSet(address account_) public nonReentrant {
    require(accountToPropertyCount[account_]['CONN_AVE'] > 0, 'CONN_AVE');
    require(accountToPropertyCount[account_]['VER_AVE'] > 0, 'VER_AVE');
    require(accountToPropertyCount[account_]['ORI_AVE'] > 0, 'ORI_AVE');
    
    bool conn_ave = false;
    bool ver_ave = false;
    bool ori_ave = false;
    uint256 tokenId;

    for (uint256 index = balanceOf(account_) - 1; index >= 0 ; index--) {
      tokenId = tokenOfOwnerByIndex(account_, index);
      
      if (conn_ave == false && s_requests[tokenIdToRequest[tokenId]].randomWord > BAL_AVE && s_requests[tokenIdToRequest[tokenId]].randomWord <= CONN_AVE) {
        // burn property and update count
        _burn(tokenId);
        conn_ave = true;
        accountToPropertyCount[account_]['CONN_AVE'] -= 1;
      } else if (ver_ave == false && s_requests[tokenIdToRequest[tokenId]].randomWord > CONN_AVE && s_requests[tokenIdToRequest[tokenId]].randomWord <= VER_AVE) {
        // burn property and update count
        _burn(tokenId);
        ver_ave = true;
        accountToPropertyCount[account_]['VER_AVE'] -= 1;
      } else if (ori_ave == false && s_requests[tokenIdToRequest[tokenId]].randomWord > VER_AVE && s_requests[tokenIdToRequest[tokenId]].randomWord <= ORI_AVE) {
        // burn property and update count
        _burn(tokenId);
        ori_ave = true;
        accountToPropertyCount[account_]['ORI_AVE'] -= 1;
      } else if (conn_ave == true && ver_ave == true && ori_ave == true) {
        // mint prize NFT
        PRIZES.mintLightBlue(account_);
        return;
      }
    }
  }
}