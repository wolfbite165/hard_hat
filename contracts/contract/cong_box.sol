// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "../interface/IHalo.sol";

contract HaloBox is ERC721Enumerable, Ownable {
    using Strings for uint256;
    string public myBaseURI;
    uint currentId = 1;
    address public superMinter;
    mapping(address => uint) public minters;
    constructor() ERC721('HALO Box', 'HALO') {
        myBaseURI = "123456";
        superMinter = _msgSender();
    }


    function setMinters(address addr_, uint amount_) external onlyOwner {
        minters[addr_] = amount_;
    }

    function setSuperMinter(address addr) external onlyOwner {
        superMinter = addr;
    }

    function mint(address player) public {
        if (_msgSender() != superMinter) {
            require(minters[_msgSender()] > 0, 'no mint amount');
            minters[_msgSender()] -= 1;
        }
        _mint(player, currentId);
        currentId ++;
    }
    
    function mintBatch(address player, uint amount) public{
        if (_msgSender() != superMinter) {
            require(minters[_msgSender()] >= amount, 'no mint amount');
            minters[_msgSender()] -= amount;
        }
        for(uint i = 0; i < amount; i ++){
            _mint(player, currentId);
            currentId ++;
        }
    }

    function checkUserBoxList(address player) public view returns (uint[] memory){
        uint tempBalance = balanceOf(player);
        uint[] memory list = new uint[](tempBalance);
        uint token;
        for (uint i = 0; i < tempBalance; i++) {
            token = tokenOfOwnerByIndex(player, i);
            list[i] = token;
        }
        return list;

    }
    
    function setBaseUri(string memory uri) public onlyOwner{
        myBaseURI = uri;
    }

    function tokenURI(uint256 tokenId_) override public view returns (string memory) {
        require(_exists(tokenId_), "nonexistent token");
        return string(abi.encodePacked(myBaseURI,'box.png'));
    }


    function burn(uint tokenId_) public returns (bool){
        require(_isApprovedOrOwner(_msgSender(), tokenId_), "burner isn't owner");
        _burn(tokenId_);
        return true;
    }

}