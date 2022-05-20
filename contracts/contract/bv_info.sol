// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BvInfo is Ownable {
    uint public price;
    address public pair;
    address public bvt;
    address public usdt;
    uint[] public priceList;
    mapping(address => bool) public admin;

    function setAdmin(address addr, bool b) external onlyOwner {
        admin[addr] = b;
    }

    function setPrice(uint price_) external onlyOwner {
        price = price_;
    }

    function setPair(address pair_) external onlyOwner {
        pair = pair_;
    }

    function setToken(address u_, address bvt_) external onlyOwner {
        usdt = u_;
        bvt = bvt_;
    }

    function rand(uint256 _length, uint seed) internal view returns (uint256) {
        uint256 random = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, seed)));
        return random % _length + 1;
    }

    function addPrice() external {
        require(admin[msg.sender], 'not admin');
        uint seed = gasleft();
        if (rand(3, seed) != 3) {
            return;
        }
        if (priceList.length <= 10) {
            priceList.push(getPairPrice());
            return;
        }
        uint index = rand(10, seed * 2) - 1;
        priceList[index] = priceList[9];
        priceList.pop();
    }

    function getPairPrice() internal view returns (uint){
        uint u = IERC20(usdt).balanceOf(pair);
        uint token = IERC20(bvt).balanceOf(pair);
        return (u * 1e18 / token);
    }

    function getBVTPrice() external view returns (uint){
        if (price != 0) {
            return price;
        }
        uint temp;
        for (uint i = 0; i < priceList.length; i++) {
            temp += priceList[i];
        }
        uint out = temp / priceList.length;
        return out;
    }


}