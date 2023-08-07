// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Prizes is ERC721Enumerable, ReentrancyGuard  {
  using Counters for Counters.Counter;
  
  // *** max prizes ***
  // constants
  uint256 constant MAX_BROWN = 10;
  uint256 constant MAX_LIGHT_BLUE = 10;
  // prizes claimed by set
  mapping(string => uint256) public setTypeToClaimed;
  
  // *** NFT - prizes ***
  Counters.Counter private _nextTokenId;
  mapping(string => uint256[]) public setTypeToTokenIds;

  // *** events ***
  event PrizeMinted(uint256 tokenId, uint256 indexed account, string indexed setType);

  constructor(
  ) ERC721("Prizes", "P") {
    // start at token id = 1
    _nextTokenId.increment();
  }

  // Brown Set: claim prize and mint NFT 
  // NOTE: In production, add access control role (game pieces contract)
  function mintBrown(address account_) public {
    require(setTypeToClaimed['BROWN'] < MAX_BROWN , 'ALL_CLAIMED_BROWN');
    
    uint256 tokenId = _nextTokenId.current();
    _mint(account_, tokenId);
    _nextTokenId.increment();

    setTypeToClaimed['BROWN'] += 1;
    setTypeToTokenIds['BROWN'].push(tokenId);
  }

  // Light Blue Set: claim prize and mint NFT 
  // NOTE: In production, add access control role (game pieces contract)
  function mintLightBlue(address account_) public {
    require(setTypeToClaimed['LIGHT_BLUE'] < MAX_LIGHT_BLUE , 'ALL_CLAIMED_LIGHT_BLUE');
    
    uint256 tokenId = _nextTokenId.current();
    _mint(account_, tokenId);
    _nextTokenId.increment();

    setTypeToClaimed['LIGHT_BLUE'] += 1;
    setTypeToTokenIds['LIGHT_BLUE'].push(tokenId);
  }
}