// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../interface/IHalo.sol";

contract HaloBoxSell is OwnableUpgradeable {
    struct UserInfo{
        uint toClaim;
        uint claimed;
        uint buyAmount;
    }
    IHalo public box;
    mapping(address => UserInfo) public userInfo;
    uint public price;
    uint public buyLimit;
    IERC20 public USDT;
    IERC20 public BVG;
    IHalo1155 public ticket;
    uint public BvgPrice;
    uint public totalBox;
    uint boxAmount;
    uint shredAmount;
    uint normalAmount;
    uint creationAmount;
    uint randomSeed;
    function rand(uint256 _length) internal returns (uint256) {
        uint256 random = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, randomSeed)));
        randomSeed ++;
        return random % _length + 1;
    }
    
    function initialize() public initializer{
        __Context_init_unchained();
        __Ownable_init_unchained();
        BvgPrice = 1e14;
        totalBox = 200000;
        boxAmount = 50000;
        creationAmount = 200;
        normalAmount = 10000;
        shredAmount = 139800;
    }
    function setPreAmount(address addr, uint amount) external onlyOwner{
        userInfo[addr].toClaim = amount;
    }
    
    function setPreAmountBatch(address[] memory addr, uint[] memory amount) external onlyOwner{
        require(addr.length == amount.length,'wrong input');
        for(uint i = 0; i < addr.length; i ++){
            userInfo[addr[i]].toClaim = amount[i];
        }
    }
    
    function setHaloBox(address addr) external onlyOwner{
        box = IHalo(addr);
    }
    
    function setTicket(address addr) external onlyOwner {
        ticket = IHalo1155(addr);
    }
    
    function setToken(address u_) external onlyOwner{
        USDT = IERC20(u_);
    }
    function setPrice(uint price_) external onlyOwner{
        price = price_;
    }
    function ClaimBox(uint amount) external{
        require(amount <= 10 ,'out of limit');
        require(userInfo[msg.sender].toClaim >= amount,'no pre amount');
        box.mintBatch(msg.sender,amount);
        userInfo[msg.sender].toClaim -= amount;
        userInfo[msg.sender].claimed += amount;
        
    }
    
    function buyBox(uint amount) external {
        require(amount <= 10 ,'out of limit');
        uint total = amount * price;
        USDT.transferFrom(msg.sender,address(this),total);
        box.mintBatch(msg.sender,amount);
        userInfo[msg.sender].buyAmount += amount;
    }
    
    
    function safePull(address token,address wallet, uint amount) external onlyOwner{
        IERC20(token).transfer(wallet,amount);
    }
}