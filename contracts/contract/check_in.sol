// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../interface/IPlanet.sol";

contract CheckIn is OwnableUpgradeable{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    IERC20Upgradeable public BVT;
    IERC20Upgradeable public BVG;
    IPlanet public planet;
    uint public walletLimit;
    uint[7] public BVTreward;
    uint[7] public BVGreward;
    struct UserInfo{
        bool[7] claimTimes;
        uint claimEndTime;
        uint claimStartTime;
        uint lastClaimTime;
        uint nextCheckTime;
    }
    mapping(address => UserInfo) public userInfo;
    event Check(address indexed player, uint indexed index);
    
    function initialize() public initializer{
        __Context_init_unchained();
        __Ownable_init_unchained();
    }
    
    function setToken(address BVT_,address BVG_) external onlyOwner{
        BVT = IERC20Upgradeable(BVT_);
        BVG = IERC20Upgradeable(BVG_);
    }
    
    function setPlanet(address planet_) external onlyOwner{
        planet = IPlanet(planet_);
    }
    
    function setWalletLimit(uint limit) external onlyOwner{
        walletLimit = limit;
    }
    
    function setReward(uint[7] memory BVTrew, uint[7] memory BVGrew) external onlyOwner{
        BVTreward = BVTrew;
        BVGreward = BVGrew;
    }
    
    function check() external {
        require(planet.isBonding(msg.sender),'not bonding planet yet');
        require(msg.sender.balance >= walletLimit,'bnb value not enough');
        UserInfo storage info = userInfo[msg.sender];
        require(info.claimStartTime == 0 || info.claimEndTime > block.timestamp,'claim over');
        if (info.claimStartTime == 0){
            info.claimStartTime = block.timestamp - (block.timestamp % 86400);
            info.claimEndTime = info.claimStartTime + 7 days;
        }
        uint index = (block.timestamp - info.claimStartTime) / 86400;
        require(!info.claimTimes[index],'claimed');
        info.claimTimes[index] = true;
        BVT.safeTransfer(msg.sender,BVTreward[index]);
        BVG.safeTransfer(msg.sender,BVGreward[index]);
        info.lastClaimTime = block.timestamp; 
        info.nextCheckTime = block.timestamp - (block.timestamp % 86400) + 86400;
        emit Check(msg.sender,index);
    }
    
    function checkUserClaimTimes(address addr) public view returns(bool[7] memory){
        return userInfo[addr].claimTimes;
    }
    
    function checkAble(address addr) public view returns(bool){
        UserInfo storage info = userInfo[addr];
        if(!planet.isBonding(addr) || addr.balance < walletLimit){
            return false;
        }
        
        if (info.claimStartTime == 0){
            return true;
        }
        if (block.timestamp > info.claimEndTime){
            return false;
        }
        uint index = (block.timestamp - info.claimStartTime) / 86400;
        return !info.claimTimes[index];
    }
    
    function findIndex(address addr) internal view returns(uint){
        UserInfo storage info = userInfo[addr];
        if (!checkAble(addr)){
            return 0;
        }
        if (info.claimStartTime == 0){
            return 0;
        }
        
        uint index = (block.timestamp - info.claimStartTime) / 86400;
        return index;
    }
    
    function getCheckInfo(address addr) public view returns(uint,bool,uint[2] memory){
         UserInfo storage info = userInfo[addr];
         uint index = findIndex(addr);
         uint[2] memory list = [BVTreward[index],BVGreward[index]];
         return (info.nextCheckTime,checkAble(addr),list);
    }
    
    
}