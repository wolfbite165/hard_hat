// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interface/ICOW721.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../interface/ICattle1155.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import  "../interface/IPlanet.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
contract TechnologyTree is OwnableUpgradeable{
    IStable public stable;
    IERC20 public BVT;
    mapping(address => mapping(uint => uint)) public userTec;
    struct TecInfo{
        uint levelLimit;
        uint types;
        uint[] effect;
        uint[] upgradeLimit;
    }
    mapping(uint => TecInfo) public tecInfo;
    uint[] tecList;
    mapping(uint => uint) tecIndex;
    function setStable(address addr) external onlyOwner{
        stable = IStable(addr);
    }
    
    function setBVT(address addr) external onlyOwner{
        BVT = IERC20(addr);
    }
    
    function initialize() public initializer{
        __Context_init_unchained();
        __Ownable_init_unchained();
        // newTechnology(3001,1,1,[100,95,90,80,70,50],[100,250,450,700,1000]);
        // newTechnology(3002,1,3,[0,4*3600,9*3600,16*3600,25*3600,36*3600],[100,250,450,700,1000]);
        // newTechnology(1001,2,1,[100,102,105,109,114,120],[100,250,450,700,1000]);
        // newTechnology(1002,2,3,[100,102,105,109,114,120],[100,250,450,700,1000]);
        // newTechnology(1003,2,5,[0,2,5,9,14,20],[100,250,450,700,1000]);
        // newTechnology(4001,3,1,[1000,1010,1025,1045,1070,1100],[100,250,450,700,1000]);
        // newTechnology(4003,3,3,[1000,1010,1025,1045,1070,1100],[100,250,450,700,1000]);
        // newTechnology(4004,3,3,[0,4,9,15,22,30],[100,250,450,700,1000]);
        // newTechnology(4002,3,5,[1000,1010,1025,1045,1070,1100],[100,250,450,700,1000]);
    }
    
    function newTechnology(uint ID,uint types_, uint levelLimit_, uint[] memory effect, uint[] memory upgradeLimit) public onlyOwner{
        require(tecIndex[ID] == 0,'exist ID');
        tecInfo[ID].types = types_;
        tecInfo[ID].levelLimit = levelLimit_;
        tecInfo[ID].effect = effect;
        tecInfo[ID].upgradeLimit = upgradeLimit;
        tecIndex[ID] = tecList.length;
        tecList.push(ID);
    }
    
    function editTechnology(uint ID,uint types_, uint levelLimit_, uint[] memory effect, uint[] memory upgradeLimit) public onlyOwner{
        require(tecIndex[ID] != 0,'nonexistent ID');
        tecInfo[ID].types = types_;
        tecInfo[ID].levelLimit = levelLimit_;
        tecInfo[ID].effect = effect;
        tecInfo[ID].upgradeLimit = upgradeLimit;
    }
    
    function buyTec(uint ID,uint amount) external{
        require(tecInfo[ID].types != 0,'nonexistent ID');
        uint level = stable.getStableLevel(msg.sender);
        require(level >= tecInfo[ID].levelLimit,'not enough level');
        BVT.transferFrom(msg.sender,address(this),amount);
        userTec[msg.sender][ID] += amount;
    }
    
    
    function buyTecBatch(uint[] memory ids,uint[] memory amounts) external{
        require(ids.length == amounts.length,'wrong length');
        uint level = stable.getStableLevel(msg.sender);
        uint total;
        for(uint i = 0; i < ids.length; i ++){
            require(tecInfo[ids[i]].types != 0,'nonexistent ID');
            require(level >= tecInfo[ids[i]].levelLimit,'not enough level');
            total += amounts[i];
            userTec[msg.sender][ids[i]] += amounts[i];
        }
        BVT.transferFrom(msg.sender,address(this),total);
        
    }
    
    function getUserTecLevel(address addr,uint ID) public view returns(uint out){
        uint amount = userTec[addr][ID];
        uint[] memory list = tecInfo[ID].upgradeLimit;
        
        for(uint i = 0; i < list.length; i ++){
            if(amount < list[i] * 1e18){
                out = i;
                return out;
            }
        }
        out = 5;
    }
    
    function checkTecEffet(uint ID) external view returns(uint[] memory){
        return tecInfo[ID].effect;
    }
    
    function checkUserTecEffet(address addr, uint ID) external view returns(uint){
        return tecInfo[ID].effect[getUserTecLevel(addr,ID)];
    }
    
    function getUserTecLevelBatch(address addr,uint[] memory list) external view returns(uint[] memory out){
        out = new uint[](list.length);
        for(uint i = 0; i < list.length; i ++){
            out[i] = getUserTecLevel(addr,list[i]);
        }
    }
    
    function checkUserExpBatch(address addr,uint[] memory list) public view returns(uint[] memory out){
        out = new uint[](list.length);
        for(uint i = 0; i < list.length; i ++){
            out[i] = userTec[addr][list[i]];
        }
    }
}