// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

interface IMating {
    function matingTime(uint tokenId) external view returns(uint);
    
    function lastMatingTime(uint tokenId) external view returns(uint);
    
    function userMatingTimes(address addr) external view returns(uint);

    function checkMatingTime(uint tokenId) external view returns (uint);
}