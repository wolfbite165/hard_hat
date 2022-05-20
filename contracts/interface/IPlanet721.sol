// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

interface IPlanet721 {
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    function tokenByIndex(uint256 index) external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256 balance);

    function planetIdMap(uint tokenId) external view returns (uint256 cardId);

    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    
    function ownerOf(uint256 tokenId) external view returns (address owner);
    
    function mint(address player_, uint type_) external returns (uint256);
    
    function changeType(uint tokenId, uint type_) external;
}