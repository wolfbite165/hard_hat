// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IHalo{
    function mintBatch(address player, uint amount) external;
    
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    
    function burn(uint tokenId_) external returns (bool);
}
interface IHalo1155{

    function mint(address to_, uint cardId_, uint amount_) external returns (bool);

    function balanceOf(address account, uint256 tokenId) external view returns (uint);

    function burn(address account, uint256 id, uint256 value) external;

    function checkItemEffect(uint id_) external view returns (uint[3] memory);
    
    function itemLevel(uint id_) external view returns (uint);
    
    function itemExp(uint id_) external view returns(uint);
    
    
}