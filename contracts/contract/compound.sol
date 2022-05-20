// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../interface/ICOW721.sol";
import "../interface/Iprofile_photo.sol";
import "../interface/ICattle1155.sol";

contract Compound is OwnableUpgradeable{
    ICOW public cattle;
    ICattle1155 public item;
    IProfilePhoto public photo;
    uint public shredId;
    IStable public stable;
    uint[] public upgradeLimit;
    mapping(uint => uint) public starExp;
    
    event CompoundCattle(address indexed player, uint indexed tokenId, uint indexed targetId);
    
    function setAddress(address cattle_, address item_, address photo_, address stable_) external onlyOwner{
        cattle = ICOW(cattle_);
        item = ICattle1155(item_);
        photo = IProfilePhoto(photo_);
        stable = IStable(stable_);
    }
    function initialize() public initializer{
        __Context_init_unchained();
        __Ownable_init_unchained();
        upgradeLimit = [30 days, 45 days, 60 days];
    }
    
    function setShredId(uint ids) external onlyOwner{
        shredId = ids;
    }
    
    function compoundShred() external {
        require(item.balanceOf(msg.sender,shredId) >= 10 ,'not enough shred');
        item.burn(msg.sender,shredId,10);
        uint id = cattle.currentId();
        cattle.mintNormallWithParents(msg.sender);
        uint gender = cattle.getGender(id);
        if(gender == 1){
            photo.mintBabyBull(msg.sender);
        }else{
            photo.mintBabyCow(msg.sender);
        }
    }
    
    function compoundCattle(uint tokenId,uint[] memory target) external{
        for(uint i = 0; i < target.length; i++){
            _compoundCattle(tokenId,target[i]);
        }
        
    }
    
    
    function _compoundCattle(uint tokenId, uint target) public{
        require(stable.isStable(tokenId),'not in stable');
        require(stable.CattleOwner(tokenId) == msg.sender,'not owner');
        require(cattle.deadTime(target) > block.timestamp,'dead target');
        require(!cattle.isCreation(target) && !cattle.isCreation(tokenId),'not creation cattle');
        require(cattle.getAdult(tokenId) && cattle.getAdult(target),'not adult');
        uint exp = cattle.deadTime(target) - block.timestamp;
        uint star = cattle.getStar(tokenId);
        require(star < 3 ,'already full');
        if(stable.isStable(target)){
            require(stable.CattleOwner(target) == msg.sender,'not owner');
            stable.compoundCattle(target);
        }else{
            require(cattle.ownerOf(target) == msg.sender,'not owner');
            cattle.burn(target);
        }
        if(starExp[tokenId] + exp >= upgradeLimit[star]){
            uint left = starExp[tokenId] + exp - upgradeLimit[star];
            cattle.upGradeStar(tokenId);
            for(uint i = 0; i < 3 ; i++){
                if(cattle.getStar(tokenId) < 3){
                    if(left > upgradeLimit[cattle.getStar(tokenId)]){
                        cattle.upGradeStar(tokenId);
                        left -= upgradeLimit[cattle.getStar(tokenId)];
                    }else{
                        break;
                    }
                }else{
                    break;
                }
            }
            starExp[tokenId] = left;
        }else{
            starExp[tokenId] += exp;
        }
        
        emit CompoundCattle(msg.sender,tokenId,target);
    }
    
}