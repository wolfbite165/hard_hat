// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interface/ICOW721.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../interface/IPlanet.sol";
import "../interface/ICattle1155.sol";
import "../interface/IMating.sol";
import "../interface/Iprofile_photo.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "../interface/ICompound.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

contract Mail is OwnableUpgradeable {
    using StringsUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    IERC20Upgradeable public BVT;
    IERC20Upgradeable public BVG;
    ICOW public cattle;
    IPlanet public planet;
    ICattle1155 public item;
    IStable public stable;
    IMating public mating;
    IProfilePhoto public avatar;
    IBOX public box;
    //------------------------
    ICompound public compound;
    IMilk public milk;
    address public banker;
    mapping(uint => address) public idClaim;
    mapping(address => uint) public bvgClaimed;
    mapping(address => uint) public bvtClaimed;
    mapping(address => mapping(address => uint)) public relationTypes;
    mapping(uint => address[2]) public relationIdentify;
    uint public rid;

    event ClaimMail(address indexed player, uint indexed id);
    event BondRelationship(address indexed player1, address indexed player2, uint indexed types, uint relationshipID);
    event UnBondRelationship(uint indexed relationshipID);
    function initialize() public initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function setCattle(address addr_) external onlyOwner {
        cattle = ICOW(addr_);
    }

    function setPlanet(address addr_) external onlyOwner {
        planet = IPlanet(addr_);
    }

    function setItem(address addr_) external onlyOwner {
        item = ICattle1155(addr_);
    }

    function setStable(address addr_) external onlyOwner {
        stable = IStable(addr_);
    }

    function setMating(address addr) external onlyOwner {
        mating = IMating(addr);
    }

    function setProfilePhoto(address addr) external onlyOwner {
        avatar = IProfilePhoto(addr);
    }

    function setCompound(address addr) external onlyOwner {
        compound = ICompound(addr);
    }

    function setMilk(address addr) external onlyOwner {
        milk = IMilk(addr);
    }

    function setBox(address addr) external onlyOwner {
        box = IBOX(addr);
    }

    function setToken(address BVT_, address BVG_) external onlyOwner {
        BVT = IERC20Upgradeable(BVT_);
        BVG = IERC20Upgradeable(BVG_);
    }

    function setBanker(address addr) external onlyOwner {
        banker = addr;
    }
    //  rewardType : 1 for cattle,           2 for item, 3 for skin, 4 for box, 5 for BVT, 6 for BVG
    //rewardId :     1 for creation, 2 for nomral,   
    function bond(address addr1,address addr2, uint types, bytes32 r, bytes32 s, uint8 v) public {
        bytes32 hash1 = keccak256(abi.encodePacked(addr1,addr2));
        bytes32 hash2 = keccak256(abi.encodePacked(types));
        bytes32 hash = keccak256(abi.encodePacked(hash1,hash2));
        address a = ecrecover(hash, v, r, s);
        require(a == banker, "not banker");
        require(addr1 != addr2, 'wrong address');
        require(types > 0 && types <= 5, 'wrong type');
        require(relationTypes[addr1][addr2] == 0, "bonded");
        relationTypes[addr1][addr2] = types;
        relationTypes[addr2][addr1] = types;

        rid += 1;

        address[2] memory couple;
        couple[0] = addr1;
        couple[1] = addr2;
        relationIdentify[rid] = couple;

        emit BondRelationship(addr1,addr2,types,rid);
    }

    function unBond(uint relationID) external {
        address another;
        if (relationIdentify[relationID][0] == _msgSender()) {
            another = relationIdentify[relationID][1];
        } else if (relationIdentify[relationID][1] == _msgSender()){
            another = relationIdentify[relationID][0];
        }

        require(another != address(0),'no type');
        relationTypes[msg.sender][another] = 0;
        relationTypes[another][msg.sender] = 0;

        emit UnBondRelationship(relationID);
    }

    function claimMail(uint8[] memory rewardType, uint8[] memory rewardId, uint[] memory rewardAmount, bool isTax, uint id, bytes32 r, bytes32 s, uint8 v) public {
        bytes32 hash1 = keccak256(abi.encodePacked(rewardType, rewardId));
        bytes32 hash2 = keccak256(abi.encodePacked(rewardAmount));
        bytes32 hash3 = keccak256(abi.encodePacked(id, msg.sender));
        bytes32 hash4 = keccak256(abi.encodePacked(isTax));
        bytes32 hash = keccak256(abi.encodePacked(hash1, hash2, hash3, hash4));
        address a = ecrecover(hash, v, r, s);
        require(a == banker, "not banker");
        require(idClaim[id] == address(0), 'claimed');
        require(rewardType.length == rewardId.length && rewardId.length == rewardAmount.length, 'wrong length');
        for (uint i = 0; i < rewardType.length; i ++) {
            if (rewardType[i] == 0) {
                break;
            }
            _processMail(rewardType[i], rewardId[i], rewardAmount[i],isTax);
        }
        emit ClaimMail(msg.sender, id);
    }

    function _processMail(uint types, uint rewardId, uint amount, bool isTax) internal {
        if (types == 1) {
            if (rewardId == 1) {
                cattle.mint(msg.sender);
            } else {
                cattle.mintNormallWithParents(msg.sender);
            }
        } else if (types == 2) {
            item.mint(msg.sender, rewardId, amount);
        } else if (types == 3) {

        } else if (types == 4) {
            uint[2] memory par;
            box.mint(msg.sender, par);
        } else if (types == 5) {
            if (isTax) {
                uint tax = planet.findTax(msg.sender);
                uint taxAmuont = amount * tax / 100;
                planet.addTaxAmount(msg.sender, taxAmuont);
                BVT.safeTransfer(msg.sender, amount - taxAmuont);
                BVT.safeTransfer(address(planet), taxAmuont);
                bvtClaimed[msg.sender] += amount;
            }else{
                BVT.safeTransfer(msg.sender, amount);
            }

        } else if (types == 6) {
            BVG.safeTransfer(msg.sender, amount);
            bvgClaimed[msg.sender] += amount;
        }
    }
}