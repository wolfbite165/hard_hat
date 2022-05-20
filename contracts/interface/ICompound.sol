// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICompound{
    function starExp(uint tokenId) external view returns(uint);
    
    function upgradeLimit(uint star_) external view returns(uint);
}