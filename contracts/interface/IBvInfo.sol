// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBvInfo{
    function addPrice() external;
    function getBVTPrice() external view returns(uint);
}