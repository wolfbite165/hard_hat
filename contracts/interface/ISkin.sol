// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

interface ISkin{
    function mint(address player,uint skinId) external;
    function ownerOf(uint256 tokenId) external view returns (address);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}