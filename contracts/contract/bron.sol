// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../interface/ICOW721.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../interface/ICattle1155.sol";
import "../interface/Iprofile_photo.sol";
contract Cow_Born is OwnableUpgradeable {
    IBOX public box;
    ICattle1155 public item;
    ICOW public cattle;
    IProfilePhoto public photo;
    uint randomSeed;
    uint creation;
    uint normal;
    uint shred;
    uint shredId;
    event Born(address indexed sender, uint indexed reward, uint indexed cattleId, uint amount);//1 for creation cattle, 2 for normal ,3 for shred
    function initialize() public initializer{
        __Context_init_unchained();
        __Ownable_init_unchained();
        creation = 1;
        normal = 9000;
        shred = 999;
    }
    
    function rand(uint256 _length) internal returns (uint256) {
        uint256 random = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, randomSeed)));
        randomSeed ++;
        return random % _length + 1;
    }
    
    function setCattle(address cattle_) public onlyOwner{
        cattle = ICOW(cattle_);
    }
    
    function setCattle1155(address item_) external onlyOwner{
        item = ICattle1155(item_);
    }
    
    function setBox(address box_) external onlyOwner{
        box = IBOX(box_);
    }
    
    function setProfile(address addr_) external onlyOwner {
        photo = IProfilePhoto(addr_);
    }
    
    function setShredId(uint id) external onlyOwner{
        shredId = id;
    }
    
    function getParents(uint id) internal view returns(uint[2] memory){
        uint[2] memory par = box.checkParents(id);
        uint[2] memory out;
        if (par[0] == 0){
            return par;
        }
        uint gender = cattle.getGender(par[0]);
        if(gender == 1){
            return par;
        }else{
            out[0] = par[1];
            out[1] = par[0];
            return out;
        }
    }

    function born(uint boxId) external returns(uint,uint,uint){
        uint[2] memory par = getParents(boxId);
        box.burn(boxId);
        uint rew  = rand(creation + normal + shred);
        if(rew <= normal){
            uint id = cattle.currentId();
            if(par[0] != 0){
                cattle.mintNormall(msg.sender,par);
            }else{
                cattle.mintNormallWithParents(msg.sender);
            }
            uint gender = cattle.getGender(id);
            if(gender == 1){
                photo.mintBabyBull(msg.sender);
            }else{
                photo.mintBabyCow(msg.sender);
            }
            emit Born(msg.sender,2,id,1);
            return(2,1,id);
        }else if(rew <= normal + shred){
            uint amount = rand(5);
            
            item.mint(msg.sender,shredId,amount);
            emit Born(msg.sender,3,0,amount);
            return(3,amount,0);
        }else{
            uint id = cattle.currentId();
            cattle.mint(msg.sender);
            uint gender = cattle.getGender(id);
            if(gender == 1){
                photo.mintAdultBull(msg.sender);
            }else{
                photo.mintAdultCow(msg.sender);
            }
            emit Born(msg.sender,1,id,1);
            return (1,1,id);
        }

    }
    
    
    
}
