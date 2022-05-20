// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../interface/IPlanet721.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../interface/IBvInfo.sol";

contract CattlePlanet is OwnableUpgradeable, ERC721HolderUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    IERC20Upgradeable public BVG;
    IERC20Upgradeable public BVT;
    IPlanet721 public planet;
    IBvInfo public bvInfo;
    uint public febLimit;
    uint public battleTaxRate;
    uint public federalPrice;
    uint[] public currentPlanet;
    uint public upGradePlanetPrice;
    function initialize() public initializer{
        __Context_init_unchained();
        __Ownable_init_unchained();
        battleTaxRate = 30;
        federalPrice = 500 ether;
        upGradePlanetPrice = 500 ether;
    }
    struct PlanetInfo {
        address owner;
        uint tax;
        uint population;
        uint normalTaxAmount;
        uint battleTaxAmount;
        uint motherPlanet;
        uint types;
        uint membershipFee;
        uint populationLimit;
        uint federalLimit;
        uint federalAmount;
        uint totalTax;
    }

    struct PlanetType {
        uint populationLimit;
        uint federalLimit;
        uint planetTax;
    }

    struct UserInfo {
        uint level;
        uint planet;
        uint taxAmount;
    }

    struct ApplyInfo {
        uint applyAmount;
        uint applyTax;
        uint lockAmount;

    }

    mapping(uint => PlanetInfo) public planetInfo;
    mapping(address => UserInfo) public userInfo;
    mapping(address => uint) public ownerOfPlanet;
    mapping(address => ApplyInfo) public applyInfo;
    mapping(address => bool) public admin;
    mapping(uint => PlanetType) public planetType;
    mapping(uint => uint) public battleReward;
    address public banker;
    address public mail;
    event BondPlanet(address indexed player, uint indexed tokenId);
    event ApplyFederalPlanet (address indexed player, uint indexed amount, uint tax);
    event CancelApply(address indexed player);
    event NewPlanet(address indexed addr,uint indexed tokenId,uint indexed motherPlanet);
    event UpGradeTechnology(uint indexed tokenId, uint indexed tecNum);
    event UpGradePlanet(uint indexed tokenId);
    event AddTaxAmount(uint indexed PlanetID, address indexed player, uint indexed amount);
    event SetPlanetFee(uint indexed PlanetID,uint indexed fee);
    event BattleReward(uint[2] indexed planetID);
    event DeployBattleReward(uint id,uint amount);
    event DeployPlanetReward(uint id,uint amount);
    event ReplacePlanet(address indexed newOwner,uint indexed tokenId);
    event PullOutCard(address indexed player,uint indexed id);
    modifier onlyPlanetOwner(uint tokenId) {
        require(msg.sender == planetInfo[tokenId].owner, 'not planet Owner');
        _;
    }

    modifier onlyAdmin(){
        require(admin[msg.sender], 'not admin');
        _;

    }

    function setAdmin(address addr, bool b) external onlyOwner{
        admin[addr] = b;
    }

    function setToken(address BVG_, address BVT_) external onlyOwner {
        BVG = IERC20Upgradeable(BVG_);
        BVT = IERC20Upgradeable(BVT_);
    }

    function setPlanet721(address planet721_) external onlyOwner {
        planet = IPlanet721(planet721_);
    }
    
    function setBvInfo(address BvInfo) external onlyOwner{
        bvInfo = IBvInfo(BvInfo);
    }

    function setPlanetType(uint types_, uint populationLimit_, uint federalLimit_, uint planetTax_) external onlyOwner {
        planetType[types_] = PlanetType({
        populationLimit : populationLimit_,
        federalLimit : federalLimit_,
        planetTax : planetTax_
        });
    }

    function getBVTPrice() public view returns (uint){
        return bvInfo.getBVTPrice();
    }


    function bondPlanet(uint tokenId) external {
        require(userInfo[msg.sender].planet == 0, 'already bond');
        require(planetInfo[tokenId].tax > 0, 'none exits planet');
        require(planetInfo[tokenId].population < planetInfo[tokenId].populationLimit, 'out of population limit');
        if (planetInfo[tokenId].membershipFee > 0) {
            uint need = planetInfo[tokenId].membershipFee * 1e18 / getBVTPrice();
            BVT.safeTransferFrom(msg.sender, planet.ownerOf(tokenId), need);
        }
        planetInfo[tokenId].population ++;
        userInfo[msg.sender].planet = tokenId;
        emit BondPlanet(msg.sender, tokenId);
    }
    
    function userTaxAmount(address addr) external view returns(uint){
        return userInfo[addr].taxAmount;
    }


    function applyFederalPlanet(uint amount, uint tax_) external {
        require(userInfo[msg.sender].planet != 0, 'not bond planet');
        require(applyInfo[msg.sender].applyAmount == 0, 'have apply, cancel frist');
        applyInfo[msg.sender].applyTax = tax_;
        applyInfo[msg.sender].applyAmount = amount;
        applyInfo[msg.sender].lockAmount = federalPrice *1e18 / getBVTPrice();
        BVT.safeTransferFrom(msg.sender, address(this), amount + applyInfo[msg.sender].lockAmount);
        emit ApplyFederalPlanet(msg.sender, amount, tax_);
    }

    function cancelApply() external {
        require(userInfo[msg.sender].planet != 0, 'not bond planet');
        require(applyInfo[msg.sender].applyAmount > 0, 'have apply, cancel frist');
        BVT.safeTransfer(msg.sender, applyInfo[msg.sender].applyAmount + applyInfo[msg.sender].lockAmount);
        delete applyInfo[msg.sender];
        emit CancelApply(msg.sender);

    }
    
    function approveFedApply(address addr_, uint tokenId) onlyPlanetOwner(tokenId) external {
        require(applyInfo[msg.sender].applyAmount > 0, 'wrong apply address');
        require(planetInfo[tokenId].federalAmount < planetInfo[tokenId].federalLimit, 'out of federal Planet limit');
        BVT.safeTransfer(msg.sender, applyInfo[msg.sender].applyAmount);
        BVT.safeTransfer(address(0),applyInfo[msg.sender].lockAmount);
        uint id = planet.mint(addr_, 2);
        uint temp = ownerOfPlanet[msg.sender];
        require(temp == 0 || planet.ownerOf(id) != addr_, 'already have 1 planet');
        planetInfo[id].tax = applyInfo[addr_].applyTax;
        planetInfo[id].motherPlanet = tokenId;
        planetInfo[tokenId].federalAmount ++;
        ownerOfPlanet[addr_] = id;
        planetInfo[id].federalLimit = planetType[2].federalLimit;
        planetType[id].populationLimit = planetType[2].populationLimit;
        delete applyInfo[addr_];
        emit NewPlanet(addr_,id,tokenId);
        emit CancelApply(msg.sender);
    }
     function claimBattleReward(uint[2] memory planetId, bytes32 r, bytes32 s, uint8 v) public {//index 0 for winner
          bytes32 hash = keccak256(abi.encodePacked(planetId));
          address a = ecrecover(hash, v, r, s);
          require(a == banker, "not banker");
          require(msg.sender == planetInfo[planetId[0]].owner,'not planet owner');
          battleReward[planetId[0]] += planetInfo[planetId[0]].battleTaxAmount + planetInfo[planetId[1]].battleTaxAmount;
          planetInfo[planetId[0]].battleTaxAmount = 0;
          planetInfo[planetId[0]].battleTaxAmount = 0;
          emit BattleReward(planetId);
      }

    function deployBattleReward(uint id,uint amount) public{
        require(msg.sender == planetInfo[id].owner,'not planet owner');
        require(battleReward[id] >= amount,'out of reward');
        BVT.safeTransfer(mail,amount);
        if(battleReward[id] > amount){
            BVT.safeTransfer(msg.sender,battleReward[id] - amount);
        }
        battleReward[id] = 0;
        emit DeployBattleReward(id,amount);
    }

    function deployPlanetReward(uint id,uint amount) public{
        require(msg.sender == planetInfo[id].owner,'not planet owner');
        require(amount <= planetInfo[id].normalTaxAmount,'out of tax amount');
        BVT.safeTransfer(mail,amount);
        planetInfo[id].normalTaxAmount -= amount;
        emit DeployPlanetReward(id,amount);
    }

    function setBanker(address addr) external onlyOwner{
        banker = addr;
    }

    function createNewPlanet(uint tokenId) external {
        require(msg.sender == planet.ownerOf(tokenId), 'not planet owner');
        require(userInfo[msg.sender].planet == 0,'must not bond');
        require(planetInfo[tokenId].tax == 0, 'created');
        uint temp = ownerOfPlanet[msg.sender];
        require(temp == 0 , 'already have 1 planet');
        uint types = planet.planetIdMap(tokenId);
        require(planetType[types].planetTax > 0,'set Tax');
        planet.safeTransferFrom(msg.sender, address(this), tokenId);
        planetInfo[tokenId].tax = planetType[planet.planetIdMap(tokenId)].planetTax;
        planetInfo[tokenId].types = types;
        planetInfo[tokenId].federalLimit = planetType[types].federalLimit;
        planetInfo[tokenId].populationLimit = planetType[types].populationLimit;
        ownerOfPlanet[msg.sender] = tokenId;
        planetInfo[tokenId].owner = msg.sender;
        currentPlanet.push(tokenId);
        emit NewPlanet(msg.sender,tokenId,0);
    }

    function pullOutPlanetCard(uint tokenId) external {
        require(msg.sender == planetInfo[tokenId].owner, 'not the owner');
        planet.safeTransferFrom(address(this), msg.sender, tokenId);
        ownerOfPlanet[msg.sender] = 0;
        planetInfo[tokenId].owner = address(0);
        emit PullOutCard(msg.sender,tokenId);
    }
    
    function replaceOwner(uint tokenId) external{
        require(msg.sender == planet.ownerOf(tokenId), 'not planet owner');
        require(userInfo[msg.sender].planet == 0,'must not bond');
        require(planetInfo[tokenId].tax != 0, 'new planet need create');
        require(ownerOfPlanet[msg.sender] == 0,'already have 1 planet');
        planet.safeTransferFrom(msg.sender, address(this), tokenId);
        planetInfo[tokenId].owner = msg.sender;
        ownerOfPlanet[msg.sender] = tokenId;
        emit ReplacePlanet(msg.sender,tokenId);
    }

    function setMemberShipFee(uint tokenId, uint price_) onlyPlanetOwner(tokenId) external {
        planetInfo[tokenId].membershipFee = price_;
        emit SetPlanetFee(tokenId,price_);
    }


    function addTaxAmount(address addr, uint amount) external onlyAdmin {
        uint tokenId = userInfo[addr].planet;
        planetInfo[tokenId].battleTaxAmount += amount * battleTaxRate / 100;
        planetInfo[tokenId].totalTax += amount;
        userInfo[addr].taxAmount += amount;
        amount = amount * (100 - battleTaxRate) / 100;
        if (planetInfo[tokenId].motherPlanet == 0) {
            planetInfo[tokenId].normalTaxAmount += amount;
            

        } else {
            uint motherPlanet = planetInfo[tokenId].motherPlanet;
            uint feb = planetInfo[tokenId].tax;
            uint home = planetInfo[motherPlanet].tax;
            uint temp = amount * feb / home;
            planetInfo[tokenId].normalTaxAmount += temp;
            planetInfo[motherPlanet].normalTaxAmount += amount - temp;
        }

        emit AddTaxAmount(tokenId,addr,amount);

    }
    
    function upGradePlanet(uint tokenId) external onlyPlanetOwner(tokenId){
        require(planetInfo[tokenId].types == 3,'can not upgrade');
        uint cost = upGradePlanetPrice * 1e18 / getBVTPrice();
        BVT.safeTransferFrom(msg.sender,address(0),cost);
        IPlanet721(planet).changeType(tokenId,1);
        planetInfo[tokenId].types = 1;
        planetInfo[tokenId].tax = planetType[1].planetTax;
        planetInfo[tokenId].federalLimit = planetType[1].federalLimit;
        planetInfo[tokenId].populationLimit = planetType[1].populationLimit;
        emit UpGradePlanet(tokenId);
    }
    

    function findTax(address addr_) public view returns (uint){
        uint tokenId = userInfo[addr_].planet;
        if (planetInfo[tokenId].motherPlanet != 0) {
            uint motherPlanet = planetInfo[tokenId].motherPlanet;
            return planetInfo[motherPlanet].tax;
        }
        return planetInfo[tokenId].tax;
    }


    function isBonding(address addr_) external view returns (bool){
        return userInfo[addr_].planet != 0;
    }


    function getUserPlanet(address addr_) external view returns (uint){
        return userInfo[addr_].planet;
    }
    
    function checkPlanetOwner() external view returns(uint[] memory,address[] memory){
        address[] memory list = new address[](currentPlanet.length);
        for (uint i = 0; i < currentPlanet.length; i++){
            list[i] = planetInfo[currentPlanet[i]].owner;
        }
        return (currentPlanet,list);
    }


}