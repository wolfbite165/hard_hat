// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interface/ICOW721.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import  "../interface/IPlanet.sol";
import "../interface/ICattle1155.sol";
import "../interface/IMating.sol";
import "../interface/Iprofile_photo.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "../interface/ICompound.sol";
import "../interface/IMarket.sol";
import "../interface/IMail.sol";
import "../interface/ITec.sol";
contract Info is OwnableUpgradeable{

    using StringsUpgradeable for uint256;
    ICOW public cattle;
    IPlanet public planet;
    ICattle1155 public item;
    IStable public stable;
    IMating public mating;
    IProfilePhoto public avatar;
    //------------------------
    ICompound public compound;
    IMilk public milk;
    IMarket public market;
    IMail public mail;
    ITec public tec;
    function initialize() public initializer{
        __Context_init_unchained();
        __Ownable_init_unchained();
    }
    
    function setCattle(address addr_) external onlyOwner{
        cattle = ICOW(addr_);
    }

    function setTec(address addr) external onlyOwner{
        tec = ITec(addr);
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
    
    function setMating(address addr) external onlyOwner{
        mating = IMating(addr);
    }

    function setProfilePhoto(address addr) external onlyOwner{
        avatar = IProfilePhoto(addr);
    }
    
    function setCompound(address addr) external onlyOwner{
        compound = ICompound(addr);
    }
    
    function setMilk(address addr) external onlyOwner{
        milk = IMilk(addr);
    }
    
    function setMail(address addr) external onlyOwner{
        mail = IMail(addr);
    }
    
    function bullPenInfo(address addr_) external view returns(uint,uint,uint,uint[] memory) {
        (uint stableAmount ,uint exp) = stable.userInfo(addr_);
        return(stableAmount,exp,stable.getStableLevel(addr_),stable.checkUserCows(addr_));
    }
    
    function cowInfoes(uint tokenId) external view returns(uint[23] memory info1,bool[3] memory info2, uint[2] memory parents){
        info2[0] = cattle.isCreation(tokenId);
        info2[1] = stable.isUsing(tokenId);
        info2[2] = cattle.getAdult(tokenId);
        info1[0] = cattle.getGender(tokenId);
        info1[1] = cattle.getBronTime(tokenId);
        info1[2] = cattle.getEnergy(tokenId);
        info1[3] = cattle.getLife(tokenId);
        info1[4] = cattle.getGrowth(tokenId);
        info1[5] = 0;
        info1[6] = cattle.getAttack(tokenId);
        info1[7] = cattle.getStamina(tokenId);
        info1[8] = cattle.getDefense(tokenId);
        info1[9] = cattle.getMilk(tokenId);
        info1[10] = cattle.getMilkRate(tokenId);
        info1[11] = cattle.getStar(tokenId);
        info1[12] = cattle.deadTime(tokenId);
        info1[13] = stable.energy(tokenId);
        info1[14] = stable.grow(tokenId);
        info1[15] = stable.refreshTime();
        info1[16] = stable.growAmount(info1[15],tokenId);
        info1[17] = stable.feeding(tokenId);
        info1[18] = mating.matingTime(tokenId);
        info1[19] = mating.lastMatingTime(tokenId);
        info1[20] = compound.starExp(tokenId);
        info1[21] = cattle.creationIndex(tokenId);
        info1[22] = mating.checkMatingTime(tokenId);
        parents = cattle.getCowParents(tokenId);
    }
    
    function _checkUserCows(address player) internal view returns(uint male,uint female,uint creation){
        uint[] memory list1 = cattle.checkUserCowListType(player,true);
        uint[] memory list2 = cattle.checkUserCowList(player);
        creation = list1.length;
        for(uint i = 0; i < list2.length; i ++){
            if(cattle.getGender(list2[i]) == 1){
                male ++;
            }else{
                female ++;
            }
        }
        uint[] memory list3 = stable.checkUserCows(player);
        for(uint i = 0; i < list3.length; i ++){
            if(cattle.isCreation(list3[i])){
                creation ++;
            }
            if (cattle.getGender(list3[i]) == 1){
                male ++;
            }else{
                female ++;
            }
        }
    }
    
    function userCenter(address player) external view returns(uint[10] memory info){
        (info[0],info[1],info[2]) = _checkUserCows(player);
        info[3] = stable.getStableLevel(player);
        (,info[4]) = stable.userInfo(player);
        if(info[3] >= 5){
            info[5] = 0;
        }else{
            info[5] = stable.levelLimit(info[3]);
        }
        
        info[6] = mating.userMatingTimes(player);
        info[7] = planet.getUserPlanet(player);
        (info[9],info[8]) = coutingCoin(player);
    }
    
    function coutingCoin(address addr) internal view returns(uint bvg_, uint bvt_){
        bvg_ += mail.bvgClaimed(addr);
        bvt_ += mail.bvtClaimed(addr);
        (,uint temp) = milk.userInfo(addr);
        bvt_ += temp;
    }
    
    function compoundInfo(uint tokenId, uint[] memory targetId) external view returns(uint[5] memory info){
        info[0] = compound.upgradeLimit(cattle.getStar(tokenId));
        if(targetId.length == 0){
            return info;
        }
        uint star = cattle.getStar(tokenId);
        info[1] = cattle.starLimit(star);
        if (star <3){
            info[2] = cattle.starLimit(star +1);
        }
        for(uint i = 0 ;i < targetId.length; i ++){
            info[3] += cattle.deadTime(targetId[i]) - block.timestamp;
        }
        uint life = cattle.getLife(tokenId);
        uint newDeadTime = block.timestamp + (35 days * life / 10000);
        if (newDeadTime > cattle.deadTime(tokenId)){
            info[4] = newDeadTime - cattle.deadTime(tokenId);
        }else{
            info[4] = 0;
        }
        
        
    }


    function checkCreation(uint[] memory list) internal view returns(uint[] memory){
        uint amount;
        for(uint i = 0; i < list.length; i ++){
            if (cattle.isCreation(list[i])){
                amount++;
            }
        }
        uint[] memory list2 = new uint[](amount);
        amount = 0;
        for(uint i = 0; i < list.length; i ++){
            if (cattle.isCreation(list[i])){
                list2[amount] = list[i];
                amount++;
            }
        }
        return list2;
    }
    
    function compoundList(uint[] memory list1, uint[] memory list2) internal pure returns(uint[] memory){
        uint[] memory list = new uint[](list1.length + list2.length);
        for(uint i = 0; i < list1.length; i ++){
            list[i] = list1[i];
        }
        for(uint i = 0; i < list2.length; i ++){
            list[list1.length + i] = list2[i];
        }
        return list;
    }
    
    function battleInfo(uint tokenId)external view returns(uint[3] memory info,bool isDead, address owner_){
        owner_ = stable.CattleOwner(tokenId);
        info[0] = cattle.getAttack(tokenId) * tec.checkUserTecEffet(owner_,4002) / 1000;
        info[1] = cattle.getStamina(tokenId)* tec.checkUserTecEffet(owner_,4001) / 1000;
        info[2] = cattle.getDefense(tokenId)* tec.checkUserTecEffet(owner_,4003) / 1000;

        isDead = block.timestamp > cattle.deadTime(tokenId);

    }
    function getUserProfilePhoto(address addr_) public view returns(string[] memory) {
        uint l;
        uint index;
        // 1.bovine hero
        uint[] memory list1 = checkCreation(stable.checkUserCows(addr_));
        uint[] memory list2 = cattle.checkUserCowListType(addr_, true);

        uint []memory bovineHeroPhoto = compoundList(list1,list2);
        l += bovineHeroPhoto.length;

        // 2.profile photo
        uint []memory profilePhoto = avatar.getUserPhotos(addr_);
        l += profilePhoto.length;

        string[] memory profileIcons = new string[](l);
        for (uint i = 0;i < bovineHeroPhoto.length; i++) {
            profileIcons[index] = (string(abi.encodePacked("Bovine Hero #",bovineHeroPhoto[i].toString())));
            index++;
        }
        for (uint i = 0;i < profilePhoto.length; i++) {
            profileIcons[index] = (string(abi.encodePacked(profilePhoto[i].toString())));
            index++;
        }


        return profileIcons;
    }
}