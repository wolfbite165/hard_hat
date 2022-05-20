// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Halo1155 is Ownable, ERC1155Burnable {
    using Address for address;
    using Strings for uint256;

    mapping(address => mapping(uint => uint)) public minters;
    address public superMinter;
    mapping(address => bool) public admin;
    mapping(address => mapping(uint => uint))public userBurn;
    uint public burned;
    function setSuperMinter(address newSuperMinter_) public onlyOwner {
        superMinter = newSuperMinter_;
    }

    function setMinter(address newMinter_, uint itemId_, uint amount_) public onlyOwner {
        minters[newMinter_][itemId_] = amount_;
    }

    function setMinterBatch(address newMinter_, uint[] calldata ids_, uint[] calldata amounts_) public onlyOwner returns (bool) {
        require(ids_.length > 0 && ids_.length == amounts_.length, "ids and amounts length mismatch");
        for (uint i = 0; i < ids_.length; ++i) {
            minters[newMinter_][ids_[i]] = amounts_[i];
        }
        return true;
    }

    string private _name;
    string private _symbol;

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }
    struct ItemInfo{
        string name;
        uint itemId;
        uint burnedAmount;
        string tokenURI;
    }
    mapping(uint => ItemInfo) public itemInfoes;
    string public myBaseURI;
    
    mapping(uint => uint) public itemExp;
    
    constructor() ERC1155("123456") {
        _name = "halo ticket";
        _symbol = "ticket";
        myBaseURI = "123456";
    }
    
    

    function setMyBaseURI(string memory uri_) public onlyOwner {
        myBaseURI = uri_;
    }



    function mint(address to_, uint itemId_, uint amount_) public returns (bool) {
        require(amount_ > 0, "K: missing amount");

        if (superMinter != _msgSender()) {
            require(minters[_msgSender()][itemId_] >= amount_, "Cattle: not minter's calling");
            minters[_msgSender()][itemId_] -= amount_;
        }


        _mint(to_, itemId_, amount_, "");

        return true;
    }
    
    function newItem(uint id_, string memory name_, string memory tokenURI_) external onlyOwner{
        require(itemInfoes[id_].itemId == 0,'exit token');
        itemInfoes[id_].itemId = id_;
        itemInfoes[id_].name = name_;
        itemInfoes[id_].tokenURI = tokenURI_;
    }
    
    function editItem(uint id_, string memory name_, string memory tokenURI_)external onlyOwner{
        require(itemInfoes[id_].itemId != 0,'exit token');
        itemInfoes[id_].itemId = id_;
        itemInfoes[id_].name = name_;
        itemInfoes[id_].tokenURI = tokenURI_;
    }

    function mintBatch(address to_, uint256[] memory ids_, uint256[] memory amounts_) public returns (bool) {
        require(ids_.length == amounts_.length, "K: ids and amounts length mismatch");

        for (uint i = 0; i < ids_.length; i++) {

            if (superMinter != _msgSender()) {
                require(minters[_msgSender()][ids_[i]] >= amounts_[i], "Cattle: not minter's calling");
                minters[_msgSender()][ids_[i]] -= amounts_[i];
            }


        }

        _mintBatch(to_, ids_, amounts_, "");

        return true;
    }



    function burn(address account, uint256 id, uint256 value) public override {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "Cattle: caller is not owner nor approved"
        );

        burned += value;
        userBurn[account][id] += value;
        _burn(account, id, value);
    }

    function burnBatch(address account, uint256[] memory ids, uint256[] memory values) public override {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "Cattle: caller is not owner nor approved"
        );

        for (uint i = 0; i < ids.length; i++) {
            itemInfoes[i].burnedAmount += values[i];
            userBurn[account][ids[i]] += values[i];
            burned += values[i];
        }
        _burnBatch(account, ids, values);
    }

    function tokenURI(uint256 itemId_) public view returns (string memory) {
        require(itemInfoes[itemId_].itemId != 0, "K: URI query for nonexistent token");

        string memory URI = itemInfoes[itemId_].tokenURI;
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, URI))
        : URI;
    }

    function _baseURI() internal view returns (string memory) {
        return myBaseURI;
    }
}
