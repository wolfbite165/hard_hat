// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract Cattle1155 is OwnableUpgradeable, ERC1155BurnableUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    mapping(address => mapping(uint => uint)) public minters;
    address public superMinter;
    mapping(address => bool) public admin;
    mapping(address => mapping(uint => uint))public userBurn;
    mapping(uint => uint) public itemType;
    uint public itemAmount;
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

    struct ItemInfo {
        uint itemId;
        string name;
        uint currentAmount;
        uint burnedAmount;
        uint maxAmount;
        uint[3] effect;
        bool tradeable;
        string tokenURI;
    }

    mapping(uint => ItemInfo) public itemInfoes;
    mapping(uint => uint) public itemLevel;
    string public myBaseURI;
    
    mapping(uint => uint) public itemExp;
    function initialize() public initializer{
        __Context_init_unchained();
        __Ownable_init_unchained();
        __ERC1155_init('123456');
        _name = "Item";
        _symbol = "Item";
        myBaseURI = "123456";
    }
    // constructor() ERC1155("123456") {
    //     _name = "Item";
    //     _symbol = "Item";
    //     myBaseURI = "123456";
    // }
    
    
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        if (!admin[msg.sender]){
            require(itemInfoes[id].tradeable,'not tradeable');
        }
        
        _safeTransferFrom(from, to, id, amount, data);
    }
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        if(!admin[msg.sender]){
            for(uint i = 0; i < ids.length; i++){
                require(itemInfoes[ids[i]].tradeable,'not tradeable');
            }
        }
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function setMyBaseURI(string memory uri_) public onlyOwner {
        myBaseURI = uri_;
    }

    function checkItemEffect(uint id_) external view returns (uint[3] memory){
        return itemInfoes[id_].effect;
    }

    function newItem(string memory name_, uint itemId_, uint maxAmount_, uint[3] memory effect_, uint types,bool tradeable_,uint level_,uint itemExp_, string memory tokenURI_) public onlyOwner {
        require(itemId_ != 0 && itemInfoes[itemId_].itemId == 0, "Cattle: wrong itemId");

        itemInfoes[itemId_] = ItemInfo({
        itemId : itemId_,
        name : name_,
        currentAmount : 0,
        burnedAmount : 0,
        maxAmount : maxAmount_,
        effect : effect_,
        tradeable : tradeable_,
        tokenURI : tokenURI_
        });
        itemType[itemId_] = types;
        itemLevel[itemId_] = level_;
        itemAmount ++;
        itemExp[itemId_] = itemExp_;
    }
    
    function setAdmin(address addr,bool b) external onlyOwner {
        admin[addr] = b;
    }

    function editItem(string memory name_, uint itemId_, uint maxAmount_, uint[3] memory effect_,uint types, bool tradeable_,uint level_, uint itemExp_, string memory tokenURI_) public onlyOwner {
        require(itemId_ != 0 && itemInfoes[itemId_].itemId == itemId_, "Cattle: wrong itemId");

        itemInfoes[itemId_] = ItemInfo({
        itemId : itemId_,
        name : name_,
        currentAmount : itemInfoes[itemId_].currentAmount,
        burnedAmount : itemInfoes[itemId_].burnedAmount,
        maxAmount : maxAmount_,
        effect : effect_,
        tradeable : tradeable_,
        tokenURI : tokenURI_
        });
        itemType[itemId_] = types;
        itemLevel[itemId_] = level_;
        itemExp[itemId_] = itemExp_;
    }
    
    function checkTypeBatch(uint[] memory ids)external view returns(uint[] memory){
        uint[] memory out = new uint[](ids.length);
        for(uint i = 0; i < ids.length; i++){
            out[i] = itemType[ids[i]];
        }
        return out;
    }

    function mint(address to_, uint itemId_, uint amount_) public returns (bool) {
        require(amount_ > 0, "K: missing amount");
        require(itemId_ != 0 && itemInfoes[itemId_].itemId != 0, "K: wrong itemId");

        if (superMinter != _msgSender()) {
            require(minters[_msgSender()][itemId_] >= amount_, "Cattle: not minter's calling");
            minters[_msgSender()][itemId_] -= amount_;
        }

        require(itemInfoes[itemId_].maxAmount - itemInfoes[itemId_].currentAmount >= amount_, "Cattle: Token amount is out of limit");
        itemInfoes[itemId_].currentAmount += amount_;

        _mint(to_, itemId_, amount_, "");

        return true;
    }


    function mintBatch(address to_, uint256[] memory ids_, uint256[] memory amounts_) public returns (bool) {
        require(ids_.length == amounts_.length, "K: ids and amounts length mismatch");

        for (uint i = 0; i < ids_.length; i++) {
            require(ids_[i] != 0 && itemInfoes[ids_[i]].itemId != 0, "Cattle: wrong itemId");

            if (superMinter != _msgSender()) {
                require(minters[_msgSender()][ids_[i]] >= amounts_[i], "Cattle: not minter's calling");
                minters[_msgSender()][ids_[i]] -= amounts_[i];
            }

            require(itemInfoes[ids_[i]].maxAmount - itemInfoes[ids_[i]].currentAmount >= amounts_[i], "Cattle: Token amount is out of limit");
            itemInfoes[ids_[i]].currentAmount += amounts_[i];
        }

        _mintBatch(to_, ids_, amounts_, "");

        return true;
    }



    function burn(address account, uint256 id, uint256 value) public override {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "Cattle: caller is not owner nor approved"
        );

        itemInfoes[id].burnedAmount += value;
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
