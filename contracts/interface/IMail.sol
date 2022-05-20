// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMail{
    function bvgClaimed(address addr)external view returns(uint);
    function bvtClaimed(address addr)external view returns(uint);
}