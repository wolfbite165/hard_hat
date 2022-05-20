// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interface/ICOW721.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../interface/ICattle1155.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import  "../interface/IPlanet.sol";
import "../interface/Iprofile_photo.sol";
contract Stable is OwnableUpgradeable , ERC721HolderUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    ICOW public cattle;
    IERC20Upgradeable public BVT;
    IERC20Upgradeable public BVG;
    IPlanet public planet;
    IProfilePhoto public photo;
    uint[] public stablePrice;
    uint public forageId;
    mapping(uint => bool) public isStable;
    mapping(uint => bool) _isUsing;
    mapping(uint => address) public CattleOwner;
    mapping(address => bool) public admin;
    mapping(uint => uint) public feeding;
    mapping(uint => uint) public feedingTime;
    ICattle1155 public cattleItem;
    uint public maxGrowAmount;
    uint public refreshTime;
    uint public upLevelPrice;
    uint[] public levelLimit ;
    struct UserInfo {
        uint stableAmount;
        uint stableExp;
        uint[] cows;
    }
    mapping(uint => uint) public energy;
    mapping(uint => uint) public grow;
    mapping(uint => mapping(uint => uint)) public growAmount;
    mapping(address => mapping(address => mapping(uint => bool))) public approves;
    mapping(address => UserInfo)public userInfo;
   // ------------------upgrade
    uint[] public stableAmountExp;
    uint[] public rewardRate;
    mapping(address => uint) stableLevel;
    mapping(uint => uint) public addLifeAmount;
    mapping(address => uint) public userPower;
    event Feed(uint indexed tokenId,uint indexed amount);
    event Grow(uint indexed tokenId,uint indexed amount);
    event Charge(address indexed player, uint indexed amount);
    event PutIn(address indexed player,uint indexed tokenId);
    event PutOut(address indexed player,uint indexed tokenId);
    function initialize() public initializer{
        __Context_init_unchained();
        __Ownable_init_unchained();
        levelLimit = [200,300,450,675,1350];
        rewardRate = [100,105,110,115,120,130];
        stableAmountExp = [50,60,80];
        stablePrice = [1500 ether,2000e18,3000e18];
        upLevelPrice = 100e18;
        maxGrowAmount = 10000;
        feedingTime[0] = 600;
        feedingTime[1] = 15 * 60;
        feedingTime[2] = 20 * 60;
    }


    function setCow(address cattle_) external onlyOwner {
        cattle = ICOW(cattle_);
    }

    function setLevelLimit (uint[] calldata list_) external onlyOwner{
        levelLimit = list_;
    }
    function setForageId(uint Id_) external onlyOwner{
        forageId = Id_;
    }
    
    function setPhoto(address photo_) external onlyOwner{
        photo = IProfilePhoto(photo_);
    }
    
    function setRewardRate(uint[] memory list) external onlyOwner{
        rewardRate  = list;
    }
    function setStableAmountExp (uint[] memory list) external onlyOwner{
        stableAmountExp = list;
    }
    
    function setCattlePlanet(address planet_)external onlyOwner {
        planet = IPlanet(planet_);
    }
    function setToken(address BVT_, address BVG_) external onlyOwner {
        BVT = IERC20Upgradeable(BVT_);
        BVG = IERC20Upgradeable(BVG_);
    }
    
    function setCattle1155(address Cattle1155_) external onlyOwner{
        cattleItem = ICattle1155(Cattle1155_);
    }

    function findOnwer(uint tokenId) public view returns (address out){
        return cattle.ownerOf(tokenId);
    }


    function setStablePrice(uint[] memory price) public onlyOwner {
        stablePrice = price;
    }

    function checkUserCows(address addr_) external view returns (uint[] memory){
        return userInfo[addr_].cows;
    }

    function changeUsing(uint tokenId, bool com_) external {
        require(admin[_msgSender()], "not admin");
        _isUsing[tokenId] = com_;
    }

    function setAdmin(address addr_, bool com_) external onlyOwner {
        admin[addr_] = com_;
        cattle.setApprovalForAll(addr_,com_);
    }


    function putIn(uint tokenId) external {
        require(planet.isBonding(msg.sender),'not bonding planet');
        UserInfo storage user = userInfo[_msgSender()];
        if (user.stableAmount < 2) {
            user.stableAmount = 2;
        }
        require(cattle.deadTime(tokenId) > block.timestamp,'cattle is dead');
        require(user.cows.length < user.stableAmount, 'out of stableAmount');
        require(findOnwer(tokenId) == _msgSender(), 'not owner');
        cattle.safeTransferFrom(msg.sender,address(this),tokenId);
        CattleOwner[tokenId] = msg.sender;
        isStable[tokenId] = true;
        user.cows.push(tokenId);
        emit PutIn(msg.sender,tokenId);
    }

    function findIndex(uint[] storage list_, uint tokenId_) internal view returns (uint){
        for (uint i = 0; i < list_.length; i++) {
            if (list_[i] == tokenId_) {
                return i;
            }
        }
        return 1e18;
    }
    
    function isUsing(uint tokenId_) public view returns(bool){
        if (_isUsing[tokenId_]){
            return _isUsing[tokenId_];
        }
        return (block.timestamp < feeding[tokenId_]);
    }

    function putOut(uint tokenId) external {
        require(!isUsing(tokenId), "is Using");
        UserInfo storage user = userInfo[_msgSender()];
        require(CattleOwner[tokenId] == _msgSender(), 'not owner');
        require(isStable[tokenId], 'not in stable');
        require(user.cows.length > 0, ' no cows in stable');
        uint temp = findIndex(user.cows, tokenId);
        require(temp != 1e18,'wrong tokenId');
        user.cows[temp] = user.cows[user.cows.length - 1];
        user.cows.pop();
        CattleOwner[tokenId] = address(0);
        isStable[tokenId] = false;
        if (block.timestamp < cattle.deadTime(tokenId)){
            cattle.safeTransferFrom(address(this),msg.sender,tokenId);
        }else{
            cattle.burn(tokenId);
        }
        emit PutOut(msg.sender,tokenId);
        
    }

    function feed(uint tokenId, uint amount_,uint types) external {
        require(isStable[tokenId], 'not in stable');
        require(CattleOwner[tokenId] == _msgSender(), 'not owner');
        require(types <= 3 && types != 0,'wrong types');
        require(!isUsing(tokenId),'this cattle is using');
        require(block.timestamp < cattle.deadTime(tokenId),'dead cattle');
        uint[3]memory effect = cattleItem.checkItemEffect(types);
        cattleItem.burn(msg.sender,types,amount_);
        uint energyLimit = cattle.getEnergy(tokenId);
        require(energy[tokenId] + amount_ <= energyLimit,'out of energyLimit');
        energy[tokenId] += amount_ * effect[0];
        feeding[tokenId] = block.timestamp + (feedingTime[types - 1] * amount_);
        emit Feed(tokenId,amount_);
    }


    function growUp(uint tokenId, uint amount_) external {
        require(isStable[tokenId], 'not in stable');
        require(CattleOwner[tokenId] == _msgSender(), 'not owner');
        require(amount_ <= energy[tokenId],'out of energy');
        
        uint refresh = block.timestamp - (block.timestamp % 86400);
        if (refresh != refreshTime){
            refreshTime = refresh;
        }
        require(!cattle.isCreation(tokenId),'creation Cattle Can not grow');
        require(growAmount[refreshTime][tokenId] + amount_ <= maxGrowAmount,'out limit');
        growAmount[refreshTime][tokenId] += amount_;
        energy[tokenId] -= amount_;
        grow[tokenId] += amount_;
        if (grow[tokenId] >= 30000){
            cattle.growUp(tokenId);
            _addStableExp(msg.sender,20);
        }
        emit Grow(tokenId,amount_);
    }
    function charge(uint tokenId,uint amount_) external {
        require(CattleOwner[tokenId] == msg.sender, 'not owner');
        require(isStable[tokenId],'not in stable');
        require(energy[tokenId] >= amount_,'not enough energy');
        require(block.timestamp < cattle.deadTime(tokenId),'dead cattle');
        require(cattle.getGender(tokenId) == 1,'not bull');
        energy[tokenId] -= amount_;
        userPower[msg.sender] += amount_;
        require(amount_ <= 20000,'out of limit');
        emit Charge(msg.sender,amount_);
    }
    
    function chargeWithItem(uint itemId, uint amount_) external {
        require(itemId > 3 ,'wrong itemId');
        uint[3]memory effect = cattleItem.checkItemEffect(itemId);
        require(effect[0] > 0 ,'wrong IitemId');
        userPower[msg.sender] += effect[0] * amount_;
        require(effect[0] * amount_ <= 20000 ,'out of limit');
        _addStableExp(msg.sender,cattleItem.itemExp(itemId) * amount_);
        cattleItem.burn(msg.sender,itemId,amount_);
    }
    
    function useItem(uint tokenId, uint itemId, uint amount_) external {
        require(isStable[tokenId], 'not in stable');
        require(CattleOwner[tokenId] == _msgSender(), 'not owner');
        require(itemId > 3 ,'wrong itemId');
        require(block.timestamp < cattle.deadTime(tokenId),'dead cattle');
        uint[3]memory effect = cattleItem.checkItemEffect(itemId);
        if (effect[0] > 0){
            uint energyLimit = cattle.getEnergy(tokenId);
            energy[tokenId] += effect[0] * amount_;
            if(energy[tokenId] > energyLimit){
                energy[tokenId] = energyLimit;
            }
        }
        if (effect[1] > 0){
            uint refresh = block.timestamp - (block.timestamp % 86400);
            if (refresh != refreshTime){
                refreshTime = refresh;
            }
//            require(growAmount[refreshTime][tokenId] + (effect[1] * amount_) <= maxGrowAmount + 5000,'out limit');
            grow[tokenId] += effect[1] * amount_;
            if (grow[tokenId] >= 30000){
                
                cattle.growUp(tokenId);
                _addStableExp(msg.sender,20);
                uint gender = cattle.getGender(tokenId);
                if(gender == 1){
                    photo.mintAdultBull(msg.sender);
                }else{
                    photo.mintAdultCow(msg.sender);
                }
            }
        }
        if (effect[2] > 0){
            require(addLifeAmount[tokenId] < 10 days,'out of add Life amount');
            uint total = effect[2] * amount_;
            if(total >(10 days - addLifeAmount[tokenId])){
                cattle.addDeadTime(tokenId,10 days - addLifeAmount[tokenId]);
                addLifeAmount[tokenId] = 10 days;
            }else{
                addLifeAmount[tokenId] += total;
                cattle.addDeadTime(tokenId,total);
            }
            
            
            
        }
        _addStableExp(msg.sender,cattleItem.itemExp(itemId) * amount_);
        cattleItem.burn(msg.sender,itemId,amount_);
        
    }
    
    function costEnergy(uint tokenId, uint amount) external {
        require(admin[_msgSender()], "not admin");
        require(energy[tokenId]>= amount,'out of energy');
        require(block.timestamp < cattle.deadTime(tokenId),'dead cattle');
        energy[tokenId] -= amount;
    }
    
    function getStablePrice(address addr) external view returns(uint){
        uint amount = userInfo[addr].stableAmount;
        if(amount == 0){
            amount =2;
        }
        uint price = stablePrice[amount / 2 - 1];
        return price;
    }


    function buyStable() external {
        if (userInfo[msg.sender].stableAmount < 2) {
            userInfo[msg.sender].stableAmount = 2;
        }
        uint index = userInfo[msg.sender].stableAmount / 2 - 1;
        uint price = stablePrice[index];
        _addStableExp(msg.sender,stableAmountExp[index]);
        BVT.safeTransferFrom(_msgSender(), address(this),price);
        userInfo[_msgSender()].stableAmount ++;
    }
    
    function addStableExp(address addr, uint amount) external{
        require(admin[_msgSender()], "not admin");
        _addStableExp(addr,amount);
    }
    
    function compoundCattle(uint tokenId) external {
        require(admin[_msgSender()], "not admin");
        require(!isUsing(tokenId),'is using');
        UserInfo storage user = userInfo[CattleOwner[tokenId]];
        require(isStable[tokenId], 'not in stable');
        uint temp = findIndex(user.cows, tokenId);
        require(temp != 1e18,'wrong tokenId');
        user.cows[temp] = user.cows[user.cows.length - 1];
        user.cows.pop();
        CattleOwner[tokenId] = address(0);
        isStable[tokenId] = false;
        cattle.burn(tokenId);
    }
    
    function _addStableExp(address addr,uint amount) internal{
        if (userInfo[addr].stableExp >= 1e17){
            userInfo[addr].stableExp = 0;
        }
        uint level = stableLevel[addr];
        if(level >= 5){
            userInfo[addr].stableExp += amount;
            return;
        }
        if(userInfo[addr].stableExp + amount >= levelLimit[level]){
            uint left = userInfo[addr].stableExp + amount - levelLimit[level];
            userInfo[addr].stableExp = left;
            stableLevel[addr] ++;
        }else{
            userInfo[addr].stableExp += amount;
        }
        
    }
    
    
    function getStableLevel(address addr_) external view returns(uint){
        return stableLevel[addr_];
    }
    
    

}
