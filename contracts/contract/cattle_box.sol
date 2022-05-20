// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract CattleBox is ERC721Enumerable, Ownable {
    using Strings for uint256;
    string public myBaseURI;
    uint currentId = 200;
    address public superMinter;
    mapping(address => uint) public minters;
    constructor() ERC721('Test Cattle Box', 'Tbox') {
        myBaseURI = "123456";
        superMinter = _msgSender();
    }

    struct BoxInfo { 
        uint[2] parents;
    }

    mapping(uint => BoxInfo)  boxInfo;

    function setMinters(address addr_, uint amount_) external onlyOwner {
        minters[addr_] = amount_;
    }

    function setSuperMinter(address addr) external onlyOwner {
        superMinter = addr;
    }

    function setBaseUri(string memory uri_) external onlyOwner{
        myBaseURI = uri_;
    }

    function mint(address player, uint[2] memory parents_) public {
        if (_msgSender() != superMinter) {
            require(minters[_msgSender()] > 0, 'no mint amount');
            minters[_msgSender()] -= 1;
        }
        _mint(player, currentId);
        boxInfo[currentId] = BoxInfo({
        parents : parents_
        });
        currentId ++;

    }
    function destroy() public onlyOwner {
        selfdestruct(payable(msg.sender));
    }

    function checUserBoxList(address player) public view returns (uint[] memory){
        uint tempBalance = balanceOf(player);
        uint[] memory list = new uint[](tempBalance);
        uint token;
        for (uint i = 0; i < tempBalance; i++) {
            token = tokenOfOwnerByIndex(player, i);
            list[i] = token;
        }
        return list;

    }

    function tokenURI(uint256 tokenId_) override public view returns (string memory) {
        require(_exists(tokenId_), "nonexistent token");
        return string(abi.encodePacked(myBaseURI, "/",'1'));
    }

    function checkParents(uint tokenId_) external view returns (uint[2] memory){
        return boxInfo[tokenId_].parents;
    }


    function burn(uint tokenId_) public returns (bool){
        require(_isApprovedOrOwner(_msgSender(), tokenId_), "burner isn't owner");
        _burn(tokenId_);
        return true;
    }

}