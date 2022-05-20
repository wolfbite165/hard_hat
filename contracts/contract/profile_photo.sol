// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";


contract ProfilePhoto is OwnableUpgradeable, ERC1155Upgradeable {
    using StringsUpgradeable for uint256;

    uint public photoId;
    address public bank;

    mapping(address => bool) public minters;

    mapping(address => uint[]) public userPhotos;
    mapping(uint => ProfilePhotoDefine) photos;

    struct ProfilePhotoDefine{
        string name;
    }

    string private _name;
    string private _symbol;


    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }


    function init() public initializer {
        __Ownable_init();
        __ERC1155_init("");

        _name = "profile photo";
        _symbol = "";

        newProfilePhoto("Baby Bull");      // 1
        newProfilePhoto("Adult Bull");     // 2
        newProfilePhoto("Baby Cow");       // 3
        newProfilePhoto("Adult Cow");      // 4
        newProfilePhoto("Mystery Box");    // 5
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(isApprovedForAll(from, _msgSender()), "ERC721: transfer caller is not owner nor approved");
        require(minters[_msgSender()],"not admin");
        _safeTransferFrom(from, to, id, amount, data);
    }


    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(isApprovedForAll(from, _msgSender()), "ERC1155: transfer caller is not owner nor approved");
        require(minters[_msgSender()],"not admin");
        _safeBatchTransferFrom(from, to, ids, amounts, data);

    }

    function newMinter(address minter_) public onlyOwner {
        require(!minters[minter_],"exist minter");
        minters[minter_] = true;
    }

    function newProfilePhoto(string memory name_) public onlyOwner {
        photoId++;
        photos[photoId] = ProfilePhotoDefine({
        name:name_
        });
    }

    function mint(address addr_, uint id_) public returns(bool) {
        require(id_ > 0 && id_ <= photoId,"invalid id" );
        require(minters[_msgSender()],"not minter's calling");

        uint balance =  balanceOf(addr_, id_);
        if (balance > 0) {
            return true;
        }

        _mint(addr_, id_, 1, "");
        userPhotos[addr_].push(id_);
        return true;
    }

    function mintBabyBull(address addr_) public {
        mint(addr_,1);
    }

    function mintAdultBull(address addr_) public {
        mint(addr_,2);
    }

    function mintBabyCow(address addr_) public {
        mint(addr_,3);
    }

    function mintAdultCow(address addr_) public {
        mint(addr_,4);
    }

    function mintMysteryBox(address addr_) public {
        mint(addr_,5);
    }

    function getUserPhotos(address addr_) public view returns(uint[]memory){
        return userPhotos[addr_];
    }

    function getPhotoName(uint id_) public view returns(string memory) {
        return photos[id_].name;
    }

}