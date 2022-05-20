// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../interface/ICattle1155.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

contract ItemShop is OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    IERC20Upgradeable public BVT;
    IERC20Upgradeable public BVG;
    ICattle1155 public item;
    uint[] onSaleList;
    struct ShopInfo{
        bool onSale;
        uint left;
        uint pay;//1 for bvt , 2 for bvg;
        uint price;
        
    }
    mapping(uint => ShopInfo) public shopInfo;
    mapping(uint => uint) index;
    mapping(address => mapping(uint => uint)) public userBuyed;
    function initialize() public initializer{
        __Context_init_unchained();
        __Ownable_init_unchained();
    }
    
    function setItem(address addr_) external onlyOwner {
        item = ICattle1155(addr_);
    }
    
    function setToken(address BVT_,address BVG_) external onlyOwner {
        BVT = IERC20Upgradeable(BVT_);
        BVG = IERC20Upgradeable(BVG_);
    }
    
    function setShopInfo(uint itemId, bool isOnsale, uint sellLimit, uint payWith, uint price_) external onlyOwner{
        uint length = onSaleList.length;
        if(!isOnsale){
            require(shopInfo[itemId].onSale,'not onSale');
            onSaleList[index[itemId]] = onSaleList[length - 1];
            onSaleList.pop();
            
        }
        if(isOnsale){
            require(!shopInfo[itemId].onSale,'already onSale');
            index[itemId] = length;
            onSaleList.push(itemId);
        }
        shopInfo[itemId] = ShopInfo({
            onSale : isOnsale,
            left : sellLimit,
            pay : payWith,
            price : price_
        });
        
    }
    
    function getOnSaleList() external view returns(uint[] memory){
        return onSaleList;
    }
    
    function buyItem(uint itemId, uint amount) external{
        ShopInfo storage info = shopInfo[itemId];
        require(amount <= info.left,'out of limit');
        require(info.onSale,'not onSale');
        uint payAmount = amount * info.price;
        if(info.pay == 1){
            BVT.safeTransferFrom(msg.sender,address(this),payAmount);
        }else{
            BVG.safeTransferFrom(msg.sender,address(this),payAmount);
        }
        item.mint(msg.sender,itemId,amount);
        info.left -= amount;
    }
    
    function setItemAmount(uint itemId, uint amount) external onlyOwner{
        shopInfo[itemId].left = amount;
    }
    function setPrice(uint[] memory ids,uint[] memory prices) external onlyOwner{
        for(uint i = 0; i < ids.length; i ++){
            shopInfo[ids[i]].price = prices[i];
        }
    }
    
    function getList() external view returns(uint[] memory lists, uint[] memory lefts, uint[] memory pays, uint[] memory prices){
        lists = onSaleList;
        lefts = new uint[](onSaleList.length);
        pays = new uint[](onSaleList.length);
        prices = new uint[](onSaleList.length);
        for(uint i = 0; i < onSaleList.length; i++){
            uint id = onSaleList[i];
            lefts[i] = shopInfo[id].left;
            pays[i] = shopInfo[id].pay;
            prices[i] = shopInfo[id].price;
        }
        return (lists,lefts,pays,prices);
    }   
    
}