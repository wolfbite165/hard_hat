// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interface/ICOW721.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../interface/IPlanet.sol";
import "../interface/ICattle1155.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../interface/ITec.sol";
contract MilkFactory is OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    ICOW public cattle;
    IStable public stable;
    IPlanet public planet;
    IERC20Upgradeable public BVT;
    ICattle1155 public cattleItem;
    uint public daliyOut;
    uint public rate;
    uint public totalPower;
    uint public debt;
    uint public lastTime;
    uint public cowsAmount;
    uint public timePerEnergy;
    uint constant acc = 1e10;
    uint public technologyId;


    struct UserInfo {
        uint totalPower;
        uint[] cattleList;
        uint cliamed;
    }

    struct StakeInfo {
        bool status;
        uint milkPower;
        uint tokenId;
        uint endTime;
        uint starrtTime;
        uint claimTime;
        uint debt;

    }

    mapping(address => UserInfo) public userInfo;
    mapping(uint => StakeInfo) public stakeInfo;

    uint public totalClaimed;
    ITec public tec;
    event ClaimMilk(address indexed player, uint indexed amount);
    event RenewTime(address indexed player, uint indexed tokenId, uint indexed newEndTIme);
    event Stake(address indexed player,uint indexed tokenId);
    event UnStake(address indexed player,uint indexed tokenId);

    function initialize() public initializer{
        __Context_init_unchained();
        __Ownable_init_unchained();
       

        daliyOut = 100e18;
         rate = daliyOut / 86400;
        timePerEnergy = 60;
        technologyId = 1;

    }

    function setCattle(address cattle_) external onlyOwner {
        cattle = ICOW(cattle_);
    }
    
    function setTec(address addr) external onlyOwner{
        tec = ITec(addr);
    }

    function setItem(address item_) external onlyOwner{
        cattleItem = ICattle1155(item_);
    }

    function setStable(address stable_) external onlyOwner {
        stable = IStable(stable_);
    }

    function setPlanet(address planet_) external onlyOwner {
        planet = IPlanet(planet_);
    }

    function setBVT(address BVT_) external onlyOwner {
        BVT = IERC20Upgradeable(BVT_);
    }

    function checkUserStakeList(address addr_) public view returns (uint[] memory){
        return userInfo[addr_].cattleList;
    }

    function coutingDebt() public view returns (uint _debt){
        _debt = totalPower > 0 ? rate * (block.timestamp - lastTime) * acc / totalPower + debt : 0 + debt;
    }

    function coutingPower(address addr_, uint tokenId) public view returns (uint){
        uint milk = cattle.getMilk(tokenId) * tec.checkUserTecEffet(addr_,1001) / 100;
        uint milkRate = cattle.getMilkRate(tokenId) * tec.checkUserTecEffet(addr_,1002) / 100;
        uint power_ = (milkRate + milk) / 2;
        uint level = stable.getStableLevel(addr_);
        uint rates = stable.rewardRate(level);
        uint finalPower = power_ * rates / 100;
        return finalPower;
    }

    function caculeteCow(uint tokenId) public view returns (uint){
        StakeInfo storage info = stakeInfo[tokenId];
        if (!info.status) {
            return 0;
        }

        uint rew;
        uint tempDebt;
        if (info.claimTime < info.endTime && info.endTime < block.timestamp) {
            tempDebt = rate * (info.endTime - info.claimTime) * acc / totalPower;
            rew = info.milkPower * tempDebt / acc;
        } else {
            tempDebt = coutingDebt();
            rew = info.milkPower * (tempDebt - info.debt) / acc;
        }


        return rew;
    }

    function caculeteAllCow(address addr_) public view returns (uint){
        uint[] memory list = checkUserStakeList(addr_);
        uint rew;
        for (uint i = 0; i < list.length; i++) {
            rew += caculeteCow(list[i]);
        }
        return rew;
    }

    function userItem(uint tokenId, uint itemId, uint amount) public{
        require(stakeInfo[tokenId].status, 'not staking');
        require(stable.CattleOwner(tokenId) == msg.sender, "not cattle's owner");
        uint[3]memory effect = cattleItem.checkItemEffect(itemId);
        require(effect[0] > 0,'wrong item');
        uint energyLimit = cattle.getEnergy(tokenId);
        uint value;
        if(amount * effect[0] >= energyLimit){
            value = energyLimit;
        }else{
            value = amount * effect[0];
        }
        stakeInfo[tokenId].endTime += value * timePerEnergy;
        stable.addStableExp(msg.sender,cattleItem.itemExp(itemId) * amount);
        cattleItem.burn(msg.sender,itemId,amount);
        emit RenewTime(msg.sender, tokenId, stakeInfo[tokenId].endTime);
    }


    function claimAllMilk() public {
        uint[] memory list = checkUserStakeList(msg.sender);
        uint rew;
        for (uint i = 0; i < list.length; i++) {
            rew += caculeteCow(list[i]);
            if (block.timestamp >= stakeInfo[list[i]].endTime) {
                debt = coutingDebt();
                totalPower -= stakeInfo[list[i]].milkPower;
                lastTime = block.timestamp;
                delete stakeInfo[list[i]];
                stable.changeUsing(list[i], false);
                cowsAmount --;
                for (uint k = 0; k < userInfo[msg.sender].cattleList.length; k ++) {
                    if (userInfo[msg.sender].cattleList[k] == list[i]) {
                        userInfo[msg.sender].cattleList[k] = userInfo[msg.sender].cattleList[userInfo[msg.sender].cattleList.length - 1];
                        userInfo[msg.sender].cattleList.pop();
                    }
                }
            } else {
                stakeInfo[list[i]].claimTime = block.timestamp;
                stakeInfo[list[i]].debt = coutingDebt();
            }
        }
        uint tax = planet.findTax(msg.sender);
        uint taxAmuont = rew * tax / 100;
        totalClaimed += rew;
        planet.addTaxAmount(msg.sender, taxAmuont);
        BVT.transfer(msg.sender, rew - taxAmuont);
        BVT.transfer(address(planet), taxAmuont);
        userInfo[msg.sender].cliamed += rew - taxAmuont;
        emit ClaimMilk(msg.sender, rew);
    }
    
    function removeList(address addr, uint index) public onlyOwner{
        uint length = userInfo[addr].cattleList.length;
        userInfo[addr].cattleList[index] = userInfo[addr].cattleList[length - 1];
        userInfo[addr].cattleList.pop();
    }
    
    function coutingEnergyCost(address addr, uint amount) public view returns(uint){
        uint rates = 100 - tec.checkUserTecEffet(addr,1003);
        return (amount * rates / 100);
    }
        

    function stake(uint tokenId, uint energyCost) public {
        require(!stable.isUsing(tokenId), 'the cattle is using');
        require(stable.isStable(tokenId), 'not in the stable');
        require(stable.CattleOwner(tokenId) == msg.sender, "not cattle's owner");
        require(cattle.getAdult(tokenId),'must bu adult');
        stable.changeUsing(tokenId, true);
        userInfo[msg.sender].cattleList.push(tokenId);
        // uint power = cattle.getMilk(tokenId);
        // require(power > 0, 'only cow can stake');
        uint power = coutingPower(msg.sender, tokenId);
        uint tempDebt = coutingDebt();
        totalPower += power;
        lastTime = block.timestamp;
        debt = tempDebt;
        userInfo[msg.sender].totalPower += power;
        stakeInfo[tokenId] = StakeInfo({
        status : true,
        milkPower : power,
        tokenId : tokenId,
        endTime : findEndTime(tokenId, energyCost),
        starrtTime : block.timestamp,
        claimTime : block.timestamp,
        debt : tempDebt
        });
        stable.costEnergy(tokenId, coutingEnergyCost(msg.sender,energyCost));
        cowsAmount ++;
        emit Stake(msg.sender,tokenId);
    }

    function unStake(uint tokenId) public {
        require(stakeInfo[tokenId].status, 'not staking');
        require(stable.CattleOwner(tokenId) == msg.sender, "not cattle's owner");
        uint rew = caculeteCow(tokenId);
        if (rew != 0) {
            uint tax = planet.findTax(msg.sender);
            uint taxAmuont = rew * tax / 100;
            planet.addTaxAmount(msg.sender, taxAmuont);
            BVT.transfer(msg.sender, rew - taxAmuont);
            BVT.transfer(address(planet), taxAmuont);
            userInfo[msg.sender].cliamed += rew - taxAmuont;
            totalClaimed += rew;
        }
        debt = coutingDebt();
        totalPower -= stakeInfo[tokenId].milkPower;
        lastTime = block.timestamp;
        delete stakeInfo[tokenId];
        stable.changeUsing(tokenId, false);
        for (uint i = 0; i < userInfo[msg.sender].cattleList.length; i ++) {
            if (userInfo[msg.sender].cattleList[i] == tokenId) {
                userInfo[msg.sender].cattleList[i] = userInfo[msg.sender].cattleList[userInfo[msg.sender].cattleList.length - 1];
                userInfo[msg.sender].cattleList.pop();
            }
        }
        cowsAmount--;
        emit UnStake(msg.sender,tokenId);
    }
    
    function setDaliyOut(uint out_) external onlyOwner{
        daliyOut = out_;
        rate = daliyOut / 86400;
    }

    function renewTime(uint tokenId, uint energyCost) public {
        require(stakeInfo[tokenId].status, 'not staking');
        require(stable.CattleOwner(tokenId) == msg.sender, "not cattle's owner");
        stable.costEnergy(tokenId, energyCost);
        stakeInfo[tokenId].endTime += energyCost * timePerEnergy;
        emit RenewTime(msg.sender, tokenId, stakeInfo[tokenId].endTime);
    }

    function findEndTime(uint tokenId, uint energyCost) public view returns (uint){
        uint energyTime = block.timestamp + energyCost * timePerEnergy;
        uint deadTime = cattle.deadTime(tokenId);
        if (energyTime <= deadTime) {
            return energyTime;
        } else {
            return deadTime;
        }
    }
}