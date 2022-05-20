// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRefer{
    function checkUserInvitor(address addr) external view returns(address);
    
    function checkUserReferList(address addr) external view returns(address[] memory);
    
    function checkUserReferDirect(address addr) external view returns(uint);

}