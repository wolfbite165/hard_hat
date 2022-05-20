// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
contract Cattle_Planet721 is Ownable, ERC721Enumerable {
    // for inherit
    
    // using Address for address;
    using Strings for uint256;

    mapping(address => mapping(uint => uint)) public minters;
    address public superMinter;
    mapping(address => bool) public admin;
    uint public burned;
    uint currentID;
    function setSuperMinter(address newSuperMinter_) public onlyOwner returns (bool) {
        superMinter = newSuperMinter_;
        return true;
    }

    function setMinterBatch(address newMinter_, uint[] calldata ids_, uint[] calldata amounts_) public onlyOwner returns (bool) {
        require(ids_.length > 0 && ids_.length == amounts_.length, "ids and amounts length mismatch");
        for (uint i = 0; i < ids_.length; ++i) {
            minters[newMinter_][ids_[i]] = amounts_[i];
        }
        return true;
    }


    struct PlanetInfo {
        uint planetType;
        string name;
        uint currentAmount;
        uint burnedAmount;
        uint maxAmount;
        bool tradable;
        string tokenURI;
    }

    mapping(uint => PlanetInfo) public planetInfo;
    mapping(uint => uint) public planetIdMap;
    string public myBaseURI;
    event Mint(address indexed addr,uint indexed types,uint indexed id);
    constructor() ERC721('Test Planet','TPlanet') {
        currentID = 1;
        superMinter = _msgSender();
    }

//    function initialize() public initializer{
//        __Context_init_unchained();
//        __Ownable_init_unchained();
//        __ERC721Enumerable_init();
//        __ERC721_init('plant','Plnat');
//        currentID = 1;
//        myBaseURI = '123456';
//        superMinter = _msgSender();
//
//    }
    
    function setAdmin(address addr_, bool com_) public onlyOwner{
        admin[addr_] = com_;
    }

    function setMyBaseURI(string calldata uri_) public onlyOwner {
        myBaseURI = uri_;
    }

    function newCard(string calldata name_, uint type_, uint maxAmount_, string calldata tokenURI_, bool tradable_) public onlyOwner {
        require(type_ != 0 && planetInfo[type_].planetType == 0, "wrong planetType");

        planetInfo[type_] = PlanetInfo({
        planetType : type_,
        name : name_,
        currentAmount : 0,
        burnedAmount : 0,
        maxAmount : maxAmount_,
        tradable : tradable_,
        tokenURI : tokenURI_
        });
    }

    function editCard(string calldata name_, uint type_, uint maxAmount_, string calldata tokenURI_, bool tradable_) public onlyOwner {
        require(type_ != 0 && planetInfo[type_].planetType == type_, "wrong planetType");

        planetInfo[type_] = PlanetInfo({
        planetType : type_,
        name : name_,
        currentAmount : planetInfo[type_].currentAmount,
        burnedAmount : planetInfo[type_].burnedAmount,
        maxAmount : maxAmount_,
        tradable : tradable_,
        tokenURI : tokenURI_
        });
    }

    

    

    function mint(address player_, uint type_) public returns (uint256) {
        require(type_ != 0 && planetInfo[type_].planetType != 0, " wrong planetType");

        if (superMinter != _msgSender()) {
            require(minters[_msgSender()][type_] > 0, " not minter");
            minters[_msgSender()][type_] -= 1;
        }

        require(planetInfo[type_].currentAmount < planetInfo[type_].maxAmount, "cattle: amount out of limit");
        planetInfo[type_].currentAmount += 1;

        uint tokenId = currentID;
        currentID ++;
        planetIdMap[tokenId] = type_;
        _mint(player_, tokenId);
        emit Mint(player_,type_,tokenId);
        return tokenId;
    }

    function mintWithId(address player_, uint id_, uint tokenId_) public returns (bool) {
        require(id_ != 0 && planetInfo[id_].planetType != 0, "wrong planetType");

        if (superMinter != _msgSender()) {
            require(minters[_msgSender()][id_] > 0, "not minter");
            minters[_msgSender()][id_] -= 1;
        }

        require(planetInfo[id_].currentAmount < planetInfo[id_].maxAmount, "cattle: amount out of limit");
        planetInfo[id_].currentAmount += 1;

        planetIdMap[tokenId_] = id_;
        _mint(player_, tokenId_);
        return true;
    }
    
    function changeType(uint tokenId, uint type_) external {
        require(admin[msg.sender],'not admin');
        planetIdMap[tokenId] = type_;
    }


    

    function burn(uint tokenId_) public returns (bool){
        require(_isApprovedOrOwner(_msgSender(), tokenId_), "burner isn't owner");

        uint planetType = planetIdMap[tokenId_];
        planetInfo[planetType].burnedAmount += 1;
        burned += 1;

        _burn(tokenId_);
        return true;
    }
    function destroy() public onlyOwner {
        selfdestruct(payable(msg.sender));
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        require(planetInfo[planetIdMap[tokenId]].tradable, 'can not transfer This Planet');
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        require(planetInfo[planetIdMap[tokenId]].tradable, 'can not transfer This Planet');
        safeTransferFrom(from, to, tokenId, "");
    }


    function tokenURIType(uint256 tokenId_) public view returns (bool) {
        string memory tURI = super.tokenURI(tokenId_);
        return bytes(tURI).length > 0;
    }

    function tokenURI(uint256 tokenId_) override public view returns (string memory){
        require(_exists(tokenId_), "nonexistent token");
        return string(abi.encodePacked(myBaseURI,planetInfo[tokenId_].planetType.toString()));
    }

    function _myBaseURI() internal view returns (string memory) {
        return myBaseURI;
    }

    function checkUserPlanet(address player,uint types_) public view returns (uint[] memory){
        uint tempBalance = balanceOf(player);
        uint token;
        uint count;
        for (uint i = 0; i < tempBalance; i++) {
            token = tokenOfOwnerByIndex(player, i);
            if(planetIdMap[token] == types_){
                count++;
            }
            
        }
        uint[] memory list = new uint[](count);
        for (uint i = 0; i < tempBalance; i++) {
            uint index = 0;
            token = tokenOfOwnerByIndex(player, i);
            if(planetIdMap[token] == types_){
                list[index] = token;
                index ++;
            }
        
        }
        return list;
    }

}
