// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "../other/divestor_upgradeable.sol";
import "../interface/IERC_721.sol";
import "../interface/IERC_1155.sol";

contract AirDrop is OwnableUpgradeable, DivestorUpgradeable, ERC1155HolderUpgradeable, ERC721HolderUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    struct Meta {
        address banker;
        bool isOpen;
    }

    Meta public meta;

    mapping(uint => address) public addrList;
    mapping(uint => bool) public airdropped;
    mapping(uint => uint) public count;

    modifier onlyBanker () {
        require(_msgSender() == meta.banker || _msgSender() == owner(), "not banker's calling");
        _;
    }

    modifier isOpen {
        require(meta.isOpen, "not open yet");
        _;
    }

    function initialize() initializer public {
        meta.isOpen = true;
        __Ownable_init_unchained();
        meta.banker = 0x468a045212eE6eBe7b832c44970Dd0C66C33AEbb;
        // addrList[0] = null 
        // addrList[1] = "usdt";
        // addrList[1] = "bvg";
        // addrList[2] = "bvt";
        // addrList[3] = "item";
    }

    function setAddr(uint addrId_, address address_) public onlyOwner {
        addrList[addrId_] = address_;
    }

    function setAirdrop(uint[] calldata airdropIds_, bool[] calldata flags_) public onlyBanker returns (bool) {
        for (uint i = 0; i < airdropIds_.length; i++) {
            airdropped[airdropIds_[i]] = flags_[i];
        }
        return true;
    }

    function setBanker(address banker_) public onlyOwner {
        meta.banker = banker_;
    }

    function setIsOpen(bool b_) public onlyOwner {
        meta.isOpen = b_;
    }


    event Airdrop(uint indexed airdropId, address indexed account);
    event ClaimERC20(uint indexed airdropId, address indexed account, uint indexed amount);
    event ClaimERC721(uint indexed airdropId, address indexed account, uint indexed amount);
    event ClaimERC1155(uint indexed airdropId, address indexed account, uint indexed amount);


    function _claimERC20(uint airdropId_, uint fromAddrId_, uint amount_) private {
        IERC20Upgradeable(addrList[fromAddrId_]).transfer(_msgSender(), amount_);
        emit ClaimERC20(airdropId_, _msgSender(), amount_);
    }

    function _claimERC721(uint airdropId_, uint fromAddrId_, uint cardId_, uint amount_) private {
        I721 ERC721 = I721(addrList[fromAddrId_]);
        ERC721.mintMulti(_msgSender(), cardId_, amount_);
        emit ClaimERC721(airdropId_, _msgSender(), amount_);
    }

    function _claimERC1155(uint airdropId_, uint fromAddrId_, uint cardId_, uint amouns_) private {
        I1155(addrList[fromAddrId_]).mint(_msgSender(), cardId_, amouns_);
        emit ClaimERC1155(airdropId_, _msgSender(), amouns_);
    }

    function airdrop(uint airdropId_, uint category_, uint fromAddrId_, uint cardId_, uint amounts_, bytes32 r_, bytes32 s_, uint8 v_) isOpen public {
        bytes32 hash = keccak256(abi.encodePacked(airdropId_, category_, fromAddrId_, cardId_, amounts_, _msgSender()));
        address a = ecrecover(hash, v_, r_, s_);
        require(a == meta.banker, "Invalid signature");
        require(!airdropped[airdropId_], "already received");
        require(addrList[fromAddrId_] != address(0), "wrong from id");

        airdropped[airdropId_] = true;
        emit Airdrop(airdropId_, _msgSender());

        count[category_] += 1;
        if (category_ == 1) {
            _claimERC20(airdropId_, fromAddrId_, amounts_ * 1 ether);
            return;
        }
        if (category_ == 2) {
            _claimERC721(airdropId_, fromAddrId_, cardId_, amounts_);
            return;
        }
        if (category_ == 3) {
            _claimERC1155(airdropId_, fromAddrId_, cardId_, amounts_);

            return;
        }
    }

}