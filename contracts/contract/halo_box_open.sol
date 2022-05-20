// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../interface/IHalo.sol";

contract HaloOpen is OwnableUpgradeable{
    IHalo public box;
    IHalo1155 public ticket;
    IERC20 public BVG;
    uint creationAmount;
    uint normalAmount;
    uint boxAmount;
    uint shredAmount;
    uint public homePlanet;
    uint public pioneerPlanet;
    uint public totalBox;
    uint public BvgPrice;
    uint randomSeed;
    uint[] extractNeed;
    mapping(address => uint) public extractTimes;
    uint public extractCreationAmount;
    uint public lastDay;
    uint public currentDay;
    struct OpenInfo{
        address mostOpen;
        uint openAmount;
        address mostCost;
        uint costAmount;
        address lastExtract;
    }
    struct UserInfo{
        uint openAmount;
        uint costAmount;
    }
    mapping(uint => uint) public rewardPool;
    mapping(uint => OpenInfo) public openInfo;
    mapping(uint => mapping(address => UserInfo)) public userInfo;
    mapping(uint => mapping(address => bool)) public isClaimed;
    event Reward(address indexed addr, uint indexed reward, uint indexed amount);//1 for creation 2 for normal 3 for box 4 for shred
    mapping(uint => uint) public openTime;
    function initialize() public initializer{
        __Context_init_unchained();
        __Ownable_init_unchained();
        BvgPrice = 1e14;
        totalBox = 200000;
        boxAmount = 50000;
        creationAmount = 200;
        normalAmount = 10000;
        shredAmount = 139800;
        homePlanet = 5;
        pioneerPlanet = 20;
        extractCreationAmount = 50;
        extractNeed = [4,8,16,32];
    }
    modifier refershTime(){
        uint time = block.timestamp - ( block.timestamp % 86400);
        if(time != currentDay){
            lastDay = currentDay;
            currentDay = time;
        }
        _;
    }
    function rand(uint256 _length) internal returns (uint256) {
        uint256 random = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, randomSeed)));
        randomSeed ++;
        return random % _length + 1;
    }
    function setExtractNeed(uint[] memory need) external onlyOwner{
        extractNeed = need;
    }
    function setBVG(address addr) external onlyOwner{
        BVG = IERC20(addr);
    }
    
    function setTicket(address addr) external onlyOwner{
        ticket = IHalo1155(addr);
    }
    
    function setBox(address addr) external onlyOwner{
        box = IHalo(addr);
    }
    
    function openBox(uint tokenId) external refershTime{
        box.burn(tokenId);
        uint res = rand(boxAmount + creationAmount + normalAmount + shredAmount);
        if(res > shredAmount + boxAmount + normalAmount){
            ticket.mint(msg.sender,2,1);
            creationAmount --;
            emit Reward(msg.sender,2,1);
        }else if(res > shredAmount + boxAmount){
            ticket.mint(msg.sender,5,1);
            normalAmount --;
            emit Reward(msg.sender,5,1);
        }else if(res > shredAmount){
            ticket.mint(msg.sender,1,1);
            boxAmount --;
            emit Reward(msg.sender,1,1);
        }else{
            ticket.mint(msg.sender,6,1);
            shredAmount --;
            emit Reward(msg.sender,6,1);
        }
        userInfo[currentDay][msg.sender].openAmount++;
        if(userInfo[currentDay][msg.sender].openAmount > openInfo[currentDay].openAmount){
            openInfo[currentDay].mostOpen = msg.sender;
            openInfo[currentDay].openAmount = userInfo[currentDay][msg.sender].openAmount;
        }
        rewardPool[currentDay] += 20000 ether;
        
    }
    
    function extractNormal(uint amount) external refershTime{
        require(amount == 2 || amount == 4,'wrong amount');
        ticket.burn(msg.sender,6,amount);
        if(amount == 2){
            uint out = rand(100);
            if(out > 80){
                ticket.mint(msg.sender,1,1);
                emit Reward(msg.sender,1,1);
            }else{
                ticket.mint(msg.sender,6,1);
                BVG.transfer(msg.sender,5 ether * 1e18 / BvgPrice);
                emit Reward(msg.sender,6,1);
            }
        }else{
            uint out = rand(100);
            if(out > 85){
                ticket.mint(msg.sender,5,1);
                emit Reward(msg.sender,5,1);
            }else{
                ticket.mint(msg.sender,6,2);
                emit Reward(msg.sender,6,2);
                BVG.transfer(msg.sender,10 ether * 1e18 / BvgPrice);
            }
        }
        userInfo[currentDay][msg.sender].costAmount += amount;
        if(userInfo[currentDay][msg.sender].costAmount > openInfo[currentDay].costAmount){
            openInfo[currentDay].costAmount = userInfo[currentDay][msg.sender].costAmount;
            openInfo[currentDay].mostCost = msg.sender;
        }
        openInfo[currentDay].lastExtract = msg.sender;
        rewardPool[currentDay] += 5000 ether;
        openTime[currentDay] = block.timestamp;
    }
    
    function extractCreation() external refershTime{
        require(extractCreationAmount > 0,'no creationAmount');
        uint times = extractTimes[msg.sender];
        uint need = extractNeed[times];
        ticket.burn(msg.sender,6,need);
        uint out = rand(100);
        if(times == 0){
            if (out > 95 && extractCreationAmount > 0){
                ticket.mint(msg.sender,2,1);
                extractCreationAmount --;
                emit Reward(msg.sender,2,1);
            }else{
                BVG.transfer(msg.sender,5 ether * 1e18 / BvgPrice);
                extractTimes[msg.sender]++;
                emit Reward(msg.sender,0,5 ether * 1e18 / BvgPrice);
            }
        }else if(times == 1){
            if (out > 80 && extractCreationAmount > 0){
                ticket.mint(msg.sender,2,1);
                extractCreationAmount --;
                extractTimes[msg.sender] = 0;
                emit Reward(msg.sender,2,1);
            }else{
                BVG.transfer(msg.sender,10 ether * 1e18 / BvgPrice);
                extractTimes[msg.sender]++;
                emit Reward(msg.sender,0,10 ether * 1e18 / BvgPrice);
            }
        }else if(times == 2){
            if (out > 50 && extractCreationAmount > 0){
                ticket.mint(msg.sender,2,1);
                extractCreationAmount --;
                extractTimes[msg.sender] = 0;
                emit Reward(msg.sender,2,1);
            }else{
                BVG.transfer(msg.sender,20 ether * 1e18 / BvgPrice);
                extractTimes[msg.sender]++;
                emit Reward(msg.sender,0,20 ether * 1e18 / BvgPrice);
            }
        }else{
            ticket.mint(msg.sender,2,1);
            extractCreationAmount --;
            extractTimes[msg.sender] = 0;
            emit Reward(msg.sender,2,1);
        }
        userInfo[currentDay][msg.sender].costAmount += need;
        if(userInfo[currentDay][msg.sender].costAmount > openInfo[currentDay].costAmount){
            openInfo[currentDay].costAmount = userInfo[currentDay][msg.sender].costAmount;
            openInfo[currentDay].mostCost = msg.sender;
        }
        openInfo[currentDay].lastExtract = msg.sender;
        openTime[currentDay] = block.timestamp;
        rewardPool[currentDay] += 5000 ether;
    }
    
    function extractPioneerPlanet(uint amount) external refershTime{
        require(amount == 8 || amount == 20,'wrong amount');
        uint out = rand(1000);
        ticket.burn(msg.sender,6,amount);
        if(amount == 8){
            if(out >850){
                ticket.mint(msg.sender,3,1);
                pioneerPlanet--;
                emit Reward(msg.sender,3,1);
            }else{
                BVG.transfer(msg.sender,20 ether * 1e18 / BvgPrice);
                emit Reward(msg.sender,0,20 ether * 1e18 / BvgPrice);
            }
        }else{
            if(out >925){
                ticket.mint(msg.sender,4,1);
                homePlanet--;
                emit Reward(msg.sender,4,1);
            }else{
                BVG.transfer(msg.sender,50 ether * 1e18 / BvgPrice);
                emit Reward(msg.sender,0,50 ether * 1e18 / BvgPrice);
            }
        }
        userInfo[currentDay][msg.sender].costAmount += amount;
        if(userInfo[currentDay][msg.sender].costAmount > openInfo[currentDay].costAmount){
            openInfo[currentDay].costAmount = userInfo[currentDay][msg.sender].costAmount;
            openInfo[currentDay].mostCost = msg.sender;
        }
        rewardPool[currentDay] += 5000 ether;
        openInfo[currentDay].lastExtract = msg.sender;
        openTime[currentDay] = block.timestamp;
    }
    
    function coutingReward(address addr) public view returns(uint){
        uint rew;
        if(isClaimed[lastDay][addr]){
            return 0;
        }
        if(addr == openInfo[lastDay].lastExtract){
            rew += rewardPool[lastDay] / 2;
        }
        if(addr == openInfo[lastDay].mostCost){
            rew += rewardPool[lastDay] * 3 / 10;
        }
        if(addr == openInfo[lastDay].mostOpen){
            rew += rewardPool[lastDay] * 2 / 10;
        }
        return rew;
    }
    
    function claimReward() refershTime external{
        require(coutingReward(msg.sender) > 0,'no reward');
        BVG.transfer(msg.sender,coutingReward(msg.sender));
        isClaimed[lastDay][msg.sender] = true;
    }
}

