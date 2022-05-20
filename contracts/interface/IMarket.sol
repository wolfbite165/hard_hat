// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMarket{
    function getSellingList(uint goodsType_, address addr_) external view returns (uint[] memory);
}