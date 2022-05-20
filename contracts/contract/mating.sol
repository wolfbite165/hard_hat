// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interface/ICOW721.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../interface/IPlanet.sol";
import "../interface/Iprofile_photo.sol";
import "../interface/ITec.sol";
import "../interface/IRefer.sol";
import "../interface/ICattle1155.sol";

contract Mating is OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    ICOW public cattle;
    IBOX public box;
    IERC20Upgradeable public BVT;
    IStable public stable;
    IPlanet public planet;
    IProfilePhoto public photo;
    mapping(uint => bool) public onSale;
    mapping(uint => uint) public price;
    mapping(uint => uint) public matingTime;
    mapping(uint => uint) public lastMatingTime;
    uint public energyCost;
    mapping(uint => uint) public index;
    mapping(address => uint[]) public userUploadList;
    mapping(address => uint) public userMatingTimes;

    event UpLoad(address indexed sender_, uint indexed price, uint indexed tokenId);
    event OffSale(address indexed sender_, uint indexed tokenId);
    event Mate(address indexed player_, uint indexed tokenId, uint indexed targetTokenID);

    IERC20Upgradeable public BVG;
    uint[] mattingCostBVG;
    uint[] mattingCostBVT;
    ITec public tec;
    IRefer public refer;
    ICattle1155 public item;
    mapping(uint => uint) public excessTimes;
    mapping(address => uint) public boxClaimed;
    mapping(address => uint) public totalMatting;

    event RewardBox(address indexed player_, address indexed invitor);
    event RewardCard(address indexed player_, address indexed invitor);

    function initialize() public initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        energyCost = 1000;
    }

    function setCow(address cattle_) external onlyOwner {
        cattle = ICOW(cattle_);
    }

    function setRefer(address addr) external onlyOwner {
        refer = IRefer(addr);
    }

    function setItem(address addr) external onlyOwner {
        item = ICattle1155(addr);
    }

    function setTec(address addr) external onlyOwner {
        tec = ITec(addr);
    }

    function setToken(address BVT_, address BVG_) external onlyOwner {
        BVT = IERC20Upgradeable(BVT_);
        BVG = IERC20Upgradeable(BVG_);
    }

    function setBox(address box_) external onlyOwner {
        box = IBOX(box_);
    }

    function setMattingCost(uint[] memory bvgCost_, uint[] memory bvtCost_) external onlyOwner {
        mattingCostBVT = bvtCost_;
        mattingCostBVG = bvgCost_;
    }

    function setStable(address stable_) external onlyOwner {
        stable = IStable(stable_);
    }

    function setPlanet(address planet_) external onlyOwner {
        planet = IPlanet(planet_);
    }

    function setEnergyCost(uint cost_) external onlyOwner {
        energyCost = cost_;
    }

    function setProfile(address addr_) external onlyOwner {
        photo = IProfilePhoto(addr_);
    }

    function upLoad(uint tokenId, uint price_) external {
        require(block.timestamp - lastMatingTime[tokenId] >= 3 days, 'mating too soon');
        require(!onSale[tokenId], 'already onSale');
        require(price_ > 0, 'price is none');
        require(stable.isStable(tokenId), 'not in stable');
        require(!stable.isUsing(tokenId), 'is using');
        uint gender;
        bool audlt;
        uint hunger;
        require(stable.CattleOwner(tokenId) == msg.sender, "not cattle's owner");
        gender = cattle.getGender(tokenId);
        audlt = cattle.getAdult(tokenId);
        hunger = cattle.getEnergy(tokenId);
        costHunger(tokenId);
        if (matingTime[tokenId] == 5 && cattle.isCreation(tokenId)) {
            require(excessTimes[tokenId] > 0, 'out of limit');
        } else {
            require(matingTime[tokenId] <= 5, 'out limit');
        }
        require(hunger >= 1000 && audlt, 'not allowed');
        onSale[tokenId] = true;
        price[tokenId] = price_;
        index[tokenId] = userUploadList[msg.sender].length;
        userUploadList[msg.sender].push(tokenId);

        emit UpLoad(msg.sender, price_, tokenId);
    }

    function offSale(uint tokenId) external {
        require(onSale[tokenId], 'not onSale');
        require(stable.CattleOwner(tokenId) == msg.sender, "not cattle's owner");
        onSale[tokenId] = false;
        price[tokenId] = 0;
        uint _index = index[tokenId];
        delete index[tokenId];
        userUploadList[msg.sender][_index] = userUploadList[msg.sender][userUploadList[msg.sender].length - 1];
        userUploadList[msg.sender].pop();
        emit OffSale(msg.sender, tokenId);
    }

    function checkMatingTime(uint tokenId) public view returns (uint){
        uint nextTime = lastMatingTime[tokenId] + 3 days - (tec.checkUserTecEffet(stable.CattleOwner(tokenId), 3002) * 3600);
        return nextTime;
    }

    function checkMattingReward(address addr) internal {
        address invitor = refer.checkUserInvitor(addr);
        if (invitor == address(0)) {
            return;
        }
        totalMatting[addr]++;
        if (totalMatting[addr] >= 5) {
            item.mint(refer.checkUserInvitor(addr), 15, 1);
            totalMatting[addr] = 0;
            emit RewardCard(addr, invitor);
        }
    }

    function checkBoxReward(address addr) internal {
        address invitor = refer.checkUserInvitor(addr);
        if (invitor == address(0)) {
            return;
        }
        boxClaimed[addr]++;
        uint[2] memory par;
        if (boxClaimed[addr] >= 5) {
            box.mint(invitor, par);
            boxClaimed[addr] = 0;
            emit RewardBox(addr, invitor);
        }
    }

    function mating(uint myTokenId, uint targetTokenID) external {
        require(checkMatingTime(myTokenId) <= block.timestamp, 'matting too soon');
        require(findGender(myTokenId) != findGender(targetTokenID), 'wrong gender');
        require(findAdult(myTokenId) && findAdult(targetTokenID), 'not adult');
        require(stable.isStable(myTokenId), 'not in stable');
        require(matingTime[myTokenId] < 5 || excessTimes[myTokenId] > 1, 'out limit');
        address rec = findOwner(targetTokenID);
        costHunger(myTokenId);
        uint temp = price[targetTokenID];
        uint tax = planet.findTax(msg.sender);
        uint taxAmuont = temp * tax / 100;
        planet.addTaxAmount(msg.sender, taxAmuont);
        BVT.safeTransferFrom(msg.sender, address(planet), taxAmuont);
        BVT.safeTransferFrom(msg.sender, rec, temp - taxAmuont);
        (uint bvgCost,uint bvtCost) = coutingCost(msg.sender, myTokenId);
        BVG.safeTransferFrom(msg.sender, address(this), bvgCost);
        BVT.safeTransferFrom(msg.sender, address(this), bvtCost);
        stable.addStableExp(msg.sender, 20);
        if (matingTime[myTokenId] == 5 && cattle.isCreation(myTokenId)) {
            excessTimes[myTokenId] --;
        } else {
            matingTime[myTokenId]++;
        }
        if (matingTime[targetTokenID] == 5 && cattle.isCreation(targetTokenID)) {
            excessTimes[targetTokenID] --;
        } else {
            matingTime[targetTokenID]++;
        }
        uint[2] memory par = [myTokenId, targetTokenID];
        box.mint(_msgSender(), par);
        checkMattingReward(msg.sender);
        checkMattingReward(rec);
        checkBoxReward(msg.sender);
        onSale[myTokenId] = false;
        onSale[targetTokenID] = false;
        price[myTokenId] = 0;
        price[targetTokenID] = 0;
        userMatingTimes[msg.sender] ++;
        lastMatingTime[myTokenId] = block.timestamp;
        lastMatingTime[targetTokenID] = block.timestamp;
        uint _index = index[targetTokenID];
        delete index[targetTokenID];
        userUploadList[rec][_index] = userUploadList[rec][userUploadList[rec].length - 1];
        userUploadList[rec].pop();


        emit Mate(msg.sender, myTokenId, targetTokenID);
    }

    function addExcessTimes(uint tokenId, uint amount) external {
        require(cattle.isCreation(tokenId), 'not creation');
        item.burn(msg.sender, 15, amount);
        excessTimes[tokenId] += amount;
    }

    function selfMating(uint tokenId1, uint tokenId2) external {
        require(checkMatingTime(tokenId1) <= block.timestamp, 'matting too soon');
        require(checkMatingTime(tokenId2) <= block.timestamp, 'matting too soon');
        require(findOwner(tokenId2) == findOwner(tokenId1) && findOwner(tokenId1) == _msgSender(), 'not owner');
        require(findGender(tokenId1) != findGender(tokenId2), 'wrong gender');
        require(findAdult(tokenId1) && findAdult(tokenId2), 'not adult');
        require(stable.isStable(tokenId1) && stable.isStable(tokenId2), 'not in stable');
        // require(matingTime[tokenId1] < 5 && matingTime[tokenId2] < 5 , 'out limit');
        costHunger(tokenId2);
        stable.addStableExp(msg.sender, 20);
        (uint bvgCost,uint bvtCost) = coutingSelfCost(msg.sender, tokenId1, tokenId2);
        BVG.safeTransferFrom(msg.sender, address(this), bvgCost);
        BVT.safeTransferFrom(msg.sender, address(this), bvtCost);
        if (matingTime[tokenId1] == 5 && cattle.isCreation(tokenId1)) {
            excessTimes[tokenId1] --;
        } else {
            matingTime[tokenId1]++;
        }
        if (matingTime[tokenId2] == 5 && cattle.isCreation(tokenId2)) {
            excessTimes[tokenId2] --;
        } else {
            matingTime[tokenId2]++;
        }
        costHunger(tokenId1);
        userMatingTimes[msg.sender] ++;
        uint[2] memory par = [tokenId2, tokenId1];
        box.mint(_msgSender(), par);
        checkBoxReward(msg.sender);
        checkMattingReward(msg.sender);

        lastMatingTime[tokenId1] = block.timestamp;
        lastMatingTime[tokenId2] = block.timestamp;


    }

    function resetIndex(address addr) external {
        for (uint i = 0; i < userUploadList[addr].length; i ++) {
            index[userUploadList[addr][i]] = i;
        }
    }

    function getUserUploadList(address addr_) external view returns (uint[] memory){
        return userUploadList[addr_];
    }

    function coutingCost(address addr, uint tokenId) public view returns (uint bvg_, uint bvt_){
        uint rate = tec.checkUserTecEffet(addr, 3001);
        return (mattingCostBVG[matingTime[tokenId]] * rate / 100, mattingCostBVT[matingTime[tokenId]] * rate / 100);
    }

    function coutingSelfCost(address addr, uint tokenId1, uint tokenId2) public view returns (uint, uint){

        (uint bvgCost1,uint bvtCost1) = coutingCost(addr, tokenId1);
        (uint bvgCost2,uint bvtCost2) = coutingCost(addr, tokenId2);
        uint bvgCost = (bvgCost1 + bvgCost2) / 2;
        uint bvtCost = (bvtCost1 + bvtCost2) / 2;
        return (bvgCost, bvtCost);
    }

    function checkMatingTimeBatch(uint[] memory list) external view returns (uint[] memory out){
        out = new uint[](list.length);
        for (uint i = 0; i < list.length; i ++) {
            out[i] = matingTime[list[i]];
        }
    }

    function findAdult(uint tokenId) internal view returns (bool out){
        out = cattle.getAdult(tokenId);
    }

    function findGender(uint tokenId) internal view returns (uint gen){
        gen = cattle.getGender(tokenId);
    }

    function costHunger(uint tokenId) internal {
        stable.costEnergy(tokenId, 1000);
    }

    function findOwner(uint tokenId) internal view returns (address out){
        return stable.CattleOwner(tokenId);
    }
}