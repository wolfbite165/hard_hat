// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract CattleSkin is ERC721Enumerable, Ownable {
    using Strings for uint256;
    string public myBaseURI;
    uint currentId = 1;
    address public superMinter;
    mapping(address => uint) public minters;
    mapping(uint => uint) public skinIdMap;
    constructor() ERC721('Cattle Skin', 'Cattle Skin') {
        myBaseURI = "https://bv-test.blockpulse.net/api/nft/skin";
        superMinter = _msgSender();
    }
    struct SkinInfo{
        string name;
        uint ID;
        uint level; //f 1 for epic 2 for lengend 3 for limit
        uint[] effect;//1 for attack 2 for defense 3 for stamia 4 for life
        string URI;
        
    }
    mapping(uint => SkinInfo) public skinInfo;
    function newSkin(string memory name, uint ID, uint level, uint[] memory effect,string memory URI_) external onlyOwner{
        require(skinInfo[ID].ID == 0,'exist ID');
        skinInfo[ID] = SkinInfo({
            name : name,
            ID : ID,
            level : level,
            effect : effect,
            URI : URI_
        });
    }
    
    function editSkin(string memory name, uint ID, uint level, uint[] memory effect,string memory URI_) external onlyOwner{
        require(skinInfo[ID].ID != 0,'nonexistent ID');
        skinInfo[ID] = SkinInfo({
            name : name,
            ID : ID,
            level : level,
            effect : effect,
            URI : URI_
        });
    }

    function setMinters(address addr_, uint amount_) external onlyOwner {
        minters[addr_] = amount_;
    }
    
    function checkSkinEffect(uint skinID) public view returns(uint[] memory){
        require(skinInfo[skinID].ID != 0,'wrong skin ID');
        return skinInfo[skinID].effect;
    }

    function setSuperMinter(address addr) external onlyOwner {
        superMinter = addr;
    }

    function mint(address player,uint skinId) public {
        if (_msgSender() != superMinter) {
            require(minters[_msgSender()] > 0, 'no mint amount');
            minters[_msgSender()] -= 1;
        }
        require(skinInfo[skinId].ID != 0,'nonexistent ID');
        skinIdMap[currentId] = skinId;
        _mint(player, currentId);
        currentId ++;
    }
    
    function mintBatch(address player, uint[] memory ids) public{
        if (_msgSender() != superMinter) {
            require(minters[_msgSender()] >= ids.length, 'no mint amount');
            minters[_msgSender()] -= ids.length;
        }
        for(uint i = 0; i < ids.length; i ++){
            require(skinInfo[ids[i]].ID != 0,'nonexistent ID');
            skinIdMap[currentId] = ids[i];
            _mint(player, currentId);
            currentId ++;
        }
    }

    function checkUserSkinList(address player) public view returns (uint[] memory){
        uint tempBalance = balanceOf(player);
        uint[] memory list = new uint[](tempBalance);
        uint token;
        for (uint i = 0; i < tempBalance; i++) {
            token = tokenOfOwnerByIndex(player, i);
            list[i] = token;
        }
        return list;
    }
    
    function checkUserSkinIDList(address player) public view returns (uint[] memory){
        uint tempBalance = balanceOf(player);
        uint[] memory list = new uint[](tempBalance);
        uint token;
        for (uint i = 0; i < tempBalance; i++) {
            token = tokenOfOwnerByIndex(player, i);
            list[i] = skinIdMap[token];
        }
        return list;
    }
    
    function setBaseUri(string memory uri) public onlyOwner{
        myBaseURI = uri;
    }

    function tokenURI(uint256 tokenId_) override public view returns (string memory) {
        require(_exists(tokenId_), "nonexistent token");
        return string(abi.encodePacked(myBaseURI,"/",skinIdMap[tokenId_].toString()));
    }


    function burn(uint tokenId_) public returns (bool){
        require(_isApprovedOrOwner(_msgSender(), tokenId_), "burner isn't owner");
        _burn(tokenId_);
        return true;
    }

}