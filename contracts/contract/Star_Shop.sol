// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../interface/ICattle1155.sol";
import "../interface/IPlanet.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
contract StarShop is OwnableUpgradeable{
    struct NormalItem{
        string name;
        uint price;
        uint totalBuy;
        IERC20 payToken;
    }
    struct LimitItem{
        string name;
        uint limitTime;
        uint price;
        uint totalBuy;
        IERC20 payToken;
        uint[] itemList;
        uint[] itemAmount;

    }
    mapping(uint => NormalItem)public normalItem;
    mapping(uint => LimitItem) public limitItem;
    mapping(address => mapping(uint => uint)) public balanceOf;
    uint[] normalOnSaleList;
    uint[] limitOnSaleList;
    ICattle1155 public item;
    IPlanet public planet;
    
    
    function initialize() public initializer{
        __Context_init_unchained();
        __Ownable_init_unchained();
    }
    function setPlanet(address addr) external onlyOwner{
        planet = IPlanet(addr);
    }
    
    function setItem(address addr)external onlyOwner{
        item = ICattle1155(addr);
    }
    function setNormalPrice(uint[] memory ids,uint[] memory prices) external onlyOwner{
        for(uint i = 0; i < ids.length; i ++){
            normalItem[ids[i]].price = prices[i];
        }
    }
    function newNormalItem(uint itemID,string memory name,uint price,address payToken) external onlyOwner{
        normalItem[itemID] = NormalItem({
            name : name,
            price : price,
            totalBuy : 0,
            payToken : IERC20(payToken)
        });
        normalOnSaleList.push(itemID);
    }
    
    function editNormalItem(uint itemID,string memory name,uint price,address payToken) external onlyOwner{
        normalItem[itemID] = NormalItem({
            name : name,
            price : price,
            totalBuy :normalItem[itemID].totalBuy ,
            payToken : IERC20(payToken)
        });
    }
    
    function reSetList(uint[] memory lists) external onlyOwner{
        normalOnSaleList = lists;
    }
    
    function newLimitItem(uint itemID,string memory name,uint price,address payToken,uint limitTime,uint[] memory itemList,uint[] memory itemAmount) external onlyOwner{
        limitItem[itemID] = LimitItem({
            name : name,
            price : price,
            payToken : IERC20(payToken),
            limitTime : limitTime,
            itemList : itemList,
            itemAmount: itemAmount,
            totalBuy : 0
        });
        limitOnSaleList.push(itemID);
    }
    function editLimitItem(uint itemID,string memory name,uint price,address payToken,uint limitTime,uint[] memory itemList,uint[] memory itemAmount) external onlyOwner{
        limitItem[itemID] = LimitItem({
            name : name,
            price : price,
            payToken : IERC20(payToken),
            limitTime : limitTime,
            itemList : itemList,
            itemAmount:itemAmount,
            totalBuy : limitItem[itemID].totalBuy
        });
    }
    
    function buyNormal(uint itemID,uint amount) external {
        NormalItem storage info = normalItem[itemID];
        require(info.price > 0,'wrong itemID');
        info.payToken.transferFrom(msg.sender,address(this),info.price * amount);
        item.mint(msg.sender,itemID,amount);
        info.totalBuy += amount;
    }
    
    function buyLimit(uint itemID, uint amount) external {
        LimitItem storage info = limitItem[itemID];
        require(block.timestamp < info.limitTime,'out of time');
        require(info.price > 0,'wrong itemID');
        info.payToken.transferFrom(msg.sender,address(this),info.price * amount);
        for(uint i = 0; i < info.itemList.length; i++){
            item.mint(msg.sender,info.itemList[i],info.itemAmount[i] * amount);
        }
        info.totalBuy += amount;
    }
    
    function checkNormalOnSaleList() public view returns(uint[] memory){
        return normalOnSaleList;
    }

    function checkLimitItemlistAmount(uint limitId) public view returns(uint[] memory,uint[] memory){
        return (limitItem[limitId].itemList,limitItem[limitId].itemAmount);
    }
    
    function checkLimitOnSaleList() public view returns(uint[] memory){
        return limitOnSaleList;
    }

    function resetLimitItemList(uint[] memory list_) public onlyOwner{
        limitOnSaleList = list_;
    }
}