// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interface/ICOW721.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../interface/IBVG.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interface/IPlanet721.sol";
contract ClaimTest is OwnableUpgradeable{
    IERC20 public BVT;
    IBEP20 public BVG;
    ICOW public cattle;
    IBOX public box;
    IPlanet721 public planet;
    mapping(address => bool) public planetWhite;
    mapping(address => bool) public cattleWhite;
    uint public planetAmount;
    uint public cattleAmount;
    struct UserInfo{
        bool planetClaimed;
        bool cattleClaimed;
        bool boxClaimed;
        bool bvtClaimed;
        bool bvgClaimed;
    }
    mapping(address => UserInfo) public userInfo;
    uint public bvgClaimAmount;
    uint public bvtClaimAmount;
    uint public bvtClaimedAmount;
    uint public bvgClaimedAmount;
    uint public boxClaimedAmount;
    uint public planetClaimedAmount;
    uint public cattleClaimedAmount;
    event ClaimBox(address indexed addr);
    event ClaimCattle(address indexed addr);
    event ClaimPlanet(address indexed addr);
    event ClaimBVT(address indexed addr);
    event ClaimBVG(address indexed addr);
    function initialize() public initializer{
        __Context_init_unchained();
        __Ownable_init_unchained();
        bvgClaimAmount = 100000 ether;
        bvtClaimAmount = 5000 ether;
        BVT = IERC20(0x271E737693BE2C63e16E9Ad5a83f26B95D161C7E);
        BVG = IBEP20(0xb17B02c9e2E39C457e696ABb55C6d5A44A352dd4);
        cattle = ICOW(0xe9bf60f2590d18f90b7218538dC90da682Fb7B01);
        box = IBOX(0x96cB0Ade2e254c598b12179503C00b007EeB7861);
        planet = IPlanet721(0x86ac1F6256D9DA9cB946156AEE7b5Af93e41636a);
    }
    
    function setBvgClaimAmount(uint amount) external onlyOwner{
        bvgClaimAmount = amount;
    }
    
    function setBvtClaimAmount(uint amount) external onlyOwner{
        bvtClaimAmount = amount;
    }
    
    function setAmount(uint catttle_, uint planet_) external onlyOwner{
        cattleAmount = catttle_;
        planetAmount = planet_;
    }
    
    function setBVG(address addr) external onlyOwner{
        BVG = IBEP20(addr);
    }
    
    function setBVT(address addr) external onlyOwner{
        BVT = IERC20(addr);
    }
    
    function setCattle(address addr_) external onlyOwner{
        cattle = ICOW(addr_);
    }
    
    function setPlanet(address addr_) external onlyOwner {
        planet = IPlanet721(addr_);
    }
    
    function setBox(address addr) external onlyOwner{
        box = IBOX(addr);
    }
    
    function addPlanetWhite(address[] memory addr,bool b) external onlyOwner{
        for(uint i = 0;i < addr.length; i ++){
            planetWhite[addr[i]] = b;
        }
    }
    
    function addCattleWhite(address[] memory addr,bool b) external onlyOwner{
        for(uint i = 0;i < addr.length; i ++){
            cattleWhite[addr[i]] = b;
        }
    }
    
    function claimPlanet()external{
        require(planetAmount >0,'out of amount');
        require(planetWhite[msg.sender],'not white list');
        require(!userInfo[msg.sender].planetClaimed,'claimed');
        planet.mint(msg.sender,1);
        userInfo[msg.sender].planetClaimed = true;
        planetAmount --;
        planetClaimedAmount ++;
        emit ClaimPlanet(msg.sender);
    } 
    
    function claimCattle() external{
        require(cattleAmount > 0,'out of amount');
        require(cattleWhite[msg.sender],'not white list');
        require(!userInfo[msg.sender].cattleClaimed,'claimed');
        cattle.mint(msg.sender);
        userInfo[msg.sender].cattleClaimed = true;
        cattleClaimedAmount ++;
        cattleAmount--;
        emit ClaimCattle(msg.sender);
    }
    
    function claimBVG() external{
        require(!userInfo[msg.sender].bvgClaimed,'claimed');
        BVG.mint(msg.sender,bvgClaimAmount);
        userInfo[msg.sender].bvgClaimed = true;
        bvgClaimedAmount += bvtClaimAmount;
        emit ClaimBVG(msg.sender);
    }
    
    function claimBVT() external{
        require(BVT.balanceOf(address(this)) >= bvtClaimAmount,'out of amount');
        require(!userInfo[msg.sender].bvtClaimed,'claimed');
        BVT.transfer(msg.sender,bvtClaimAmount);
        userInfo[msg.sender].bvtClaimed = true;
        bvtClaimedAmount += bvtClaimAmount;
        emit ClaimBVT(msg.sender);
    }
    
    function claimBox() external{
        require(!userInfo[msg.sender].boxClaimed,'claimed');
        uint[2] memory par;
        box.mint(msg.sender,par);
        box.mint(msg.sender,par);
        userInfo[msg.sender].boxClaimed = true;
        boxClaimedAmount += 2;
        emit ClaimBox(msg.sender);
    }

    function checkInfo(address addr) external view returns(bool[7] memory info1,uint[5] memory info2,uint[5] memory info3){
        info1[0] = userInfo[addr].boxClaimed;
        info1[1] = userInfo[addr].cattleClaimed;
        info1[2] = userInfo[addr].bvgClaimed;
        info1[3] = userInfo[addr].bvtClaimed;
        info1[4] = userInfo[addr].planetClaimed;
        info1[5] = cattleWhite[addr];
        info1[6] = planetWhite[addr];
        info2[0] = planetAmount;
        info2[1] = cattleAmount;
        info2[2] = bvgClaimAmount;
        info2[3] = bvtClaimAmount;
        info2[4] = BVT.balanceOf(address(this));
        info3[0] = bvtClaimedAmount;
        info3[1] = bvgClaimedAmount;
        info3[2] = boxClaimedAmount;
        info3[3] = planetClaimedAmount;
        info3[4] = cattleClaimedAmount;
    }
    
}