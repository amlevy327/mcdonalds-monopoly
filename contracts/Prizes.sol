// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
//import "hardhat/console.sol";

contract Prizes is ERC721Enumerable, AccessControl, ReentrancyGuard  {
  using Counters for Counters.Counter;
  Counters.Counter private _nextTokenId;

  event PrizeMinted(uint256 tokenId, uint256 indexed account, string indexed setType);

  uint256 constant MAX_BROWN = 4;
  uint256 constant MAX_LIGHT_BLUE = 2;

  mapping(string => uint256) public setTypeToClaimed;
  mapping(string => uint256[]) public setTypeToTokenIds;

  constructor(
  ) ERC721("Prizes", "P") {
    _nextTokenId.increment();
  }

  function mintBrown(address account_) public {
    require(setTypeToClaimed['BROWN'] < MAX_BROWN , 'ALL_CLAIMED_BROWN');
    
    uint256 tokenId = _nextTokenId.current();
    _mint(account_, tokenId);
    _nextTokenId.increment();

    setTypeToClaimed['BROWN'] += 1;
    setTypeToTokenIds['BROWN'].push(tokenId);
  }

  function mintLightBlue(address account_) public {
    require(setTypeToClaimed['LIGHT_BLUE'] < MAX_LIGHT_BLUE , 'ALL_CLAIMED_LIGHT_BLUE');
    
    uint256 tokenId = _nextTokenId.current();
    _mint(account_, tokenId);
    _nextTokenId.increment();

    setTypeToClaimed['LIGHT_BLUE'] += 1;
    setTypeToTokenIds['LIGHT_BLUE'].push(tokenId);
  }

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