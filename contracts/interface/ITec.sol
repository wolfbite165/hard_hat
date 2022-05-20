// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

interface ITec{
    
    function getUserTecLevelBatch(address addr,uint[] memory list) external view returns(uint[] memory out);
    
    function getUserTecLevel(address addr,uint ID) external view returns(uint out);
    
    function checkUserExpBatch(address addr,uint[] memory list) external view returns(uint[] memory out);
    
    function checkUserTecEffet(address addr, uint ID) external view returns(uint);
}