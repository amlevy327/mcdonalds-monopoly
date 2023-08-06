// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
//import "hardhat/console.sol";
import "./Prizes.sol";

/* TODO:
-burn nfts
-access control
-refactor
*/

contract Monopoly is ERC721Enumerable, AccessControl, ReentrancyGuard, VRFConsumerBaseV2  {
  using Counters for Counters.Counter;
  Counters.Counter private _nextTokenId;

  // range
  uint256 constant MIN = 1;
  uint256 constant MAX = 2;

  // brown set
  uint256 constant MED_AVE = 1;
  uint256 constant BAL_AVE = 2;

  // light blue set
  uint256 constant CONN_AVE = 3;
  uint256 constant VER_AVE = 4;
  uint256 constant ORI_AVE = 5;

  mapping(address => mapping(string => uint256)) public accountToPropertyCount;

  event RequestSent(uint256 requestId, uint32 numWords, address indexed account, uint256 tokenId);
  event RequestFulfilled(uint256 requestId, uint256 randomWord, address indexed account, uint256 tokenId);

  bytes32 public constant MANAGER_ROLE = keccak256("MANAGER");

  Prizes public immutable PRIZES;
  
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
  mapping(uint256 => uint256) public tokenIdToRequest;

  constructor(
    uint64 subscriptionId,
    address vrfCoordinator,
    bytes32 keyHash,
    address prizes
  ) ERC721("McDonaldsMonopoly", "MM") 
    VRFConsumerBaseV2(vrfCoordinator) {
    COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    s_keyHash = keyHash;
    s_subscriptionId = subscriptionId;
    PRIZES = Prizes(prizes);
    _nextTokenId.increment();
  }
  
  // create unrevealed game piece
  // TODO: access control
  function requestRandomWords(address account_) external returns(uint256) {
    uint256 requestId = COORDINATOR.requestRandomWords(
      s_keyHash,
      s_subscriptionId,
      REQUEST_CONFIRMATIONS,
      CALLBACK_GAS_LIMIT,
      NUM_WORDS
    );

    uint256 tokenId = _nextTokenId.current();
    _mint(account_, tokenId);
    tokenIdToRequest[tokenId] = requestId;

    s_requests[requestId] = RequestStatus({
      randomWord: 0,
      exists: true,
      fulfilled: false,
      account: account_,
      tokenId: tokenId
    });
    requestIds.push(requestId);
    lastRequestId = requestId;

    emit RequestSent(requestId, NUM_WORDS, account_, tokenId);
    _nextTokenId.increment();

    return requestId;
  }

  // reveal property
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
    internal
    override
  {
    require(s_requests[requestId].exists, "REQUEST_NOT_FOUND");
    s_requests[requestId].fulfilled = true;
    uint256 randomNumber = (randomWords[0] % MAX) + MIN;
    address account = s_requests[requestId].account;
    uint256 tokenId = s_requests[requestId].tokenId;
    s_requests[requestId].randomWord = randomNumber;
    addtoPropertiesMappings(account, randomNumber);
    emit RequestFulfilled(requestId, randomNumber, account, tokenId);
  }

  function addtoPropertiesMappings(address account_, uint256 randomNumber_) internal {
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

  // revealed?
  function getRequestStatus(
    uint256 _requestId
  ) external view returns (bool fulfilled, uint256  randomWord) {
    require(s_requests[_requestId].exists, "REQUEST_NOT_FOUND");
    RequestStatus memory request = s_requests[_requestId];
    return (request.fulfilled, request.randomWord);
  } 

  function claimBrownSet(address account_) public {
    require(accountToPropertyCount[account_]['MED_AVE'] > 0, 'NO_MED_AVE');
    require(accountToPropertyCount[account_]['BAL_AVE'] > 0, 'NO_BAL_AVE');
    
    PRIZES.mintBrown(account_);
    accountToPropertyCount[account_]['MED_AVE'] -= 1;
    accountToPropertyCount[account_]['BAL_AVE'] -= 1;

    bool med_ave = false;
    bool bal_ave = false;
    uint256 tokenId;

    // TODO: need to continue testing this - had issue where only 1 of 2 nfts burned
    for (uint256 index = 0; index < balanceOf(account_); index++) {
      tokenId = tokenOfOwnerByIndex(account_, index);
      if (med_ave == true && bal_ave == true) {
        return;
      } else if (med_ave == false && s_requests[tokenIdToRequest[tokenId]].randomWord <= MED_AVE) {
        _burn(tokenId);
        med_ave = true;
      } else if (bal_ave == false && s_requests[tokenIdToRequest[tokenId]].randomWord > MED_AVE && s_requests[tokenIdToRequest[tokenId]].randomWord <= BAL_AVE) {
        _burn(tokenId);
        bal_ave = true;
      }
    }
  }

  // function claimLightBlueSet(address account_) public {
  //   require(accountToPropertyCount[account_]['CONN_AVE'] > 0, 'NO_CONN_AVE');
  //   require(accountToPropertyCount[account_]['VER_AVE'] > 0, 'NO_VER_AVE');
  //   require(accountToPropertyCount[account_]['ORI_AVE'] > 0, 'NO_ORI_AVE');
    
  //   PRIZES.mintLightBlue(account_);
  //   accountToPropertyCount[account_]['CONN_AVE'] -= 1;
  //   accountToPropertyCount[account_]['VER_AVE'] -= 1;
  //   accountToPropertyCount[account_]['ORI_AVE'] -= 1;

  //   uint256 length;
  //   uint256 tokenId;
    
  //   length = accountToPropertyTokenIds[account_]['CONN_AVE'].length;
  //   tokenId = accountToPropertyTokenIds[account_]['CONN_AVE'][length - 1];
  //   _burn(tokenId);
  //   accountToPropertyTokenIds[account_]['CONN_AVE'].pop();

  //   length = accountToPropertyTokenIds[account_]['VER_AVE'].length;
  //   tokenId = accountToPropertyTokenIds[account_]['VER_AVE'][length - 1];
  //   _burn(tokenId);
  //   accountToPropertyTokenIds[account_]['VER_AVE'].pop();

  //   length = accountToPropertyTokenIds[account_]['ORI_AVE'].length;
  //   tokenId = accountToPropertyTokenIds[account_]['ORI_AVE'][length - 1];
  //   _burn(tokenId);
  //   accountToPropertyTokenIds[account_]['ORI_AVE'].pop();
  // }

  function supportsInterface(
    bytes4 interfaceId
  )
    public
    view
    virtual
    override(ERC721Enumerable, AccessControl)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
}