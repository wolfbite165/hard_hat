// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../interface/ISkin.sol";
contract SkinShop is OwnableUpgradeable{
    ISkin public skin;
    uint[] list;
    IERC20 public BVT;
    IERC20 public U;
    address public pair;
    struct SkinInfo{
        uint price;
        bool onSale;
        uint totalBuy;
        uint limit;
    }
    mapping(uint => uint) index;
    mapping(uint => SkinInfo)public skinInfo;
    function initialize() public initializer{
        __Context_init_unchained();
        __Ownable_init_unchained();
    }
    function setSkin(address addr) external onlyOwner{
        skin = ISkin(addr);
    }
    
    function setToken(address BVT_, address U_) external onlyOwner{
        BVT = IERC20(BVT_);
        U = IERC20(U_);
    }
    
    function setPair(address addr) external onlyOwner{
        pair = addr;
    }
    
    function getBVTPrice() public view returns(uint){
        if(pair == address(0)){
            return 1 ether;
        }
        uint balance1 = BVT.balanceOf(pair);
        uint balance2 = U.balanceOf(pair);
        return(balance2 * 1e18 / balance1);
    }
    
    function newSkinInfo(uint skinId,uint price, bool onSale,uint limit) external onlyOwner{
        require(skinInfo[skinId].price == 0 ,'already on sale');
        skinInfo[skinId].price = price;
        skinInfo[skinId].onSale = onSale;
        skinInfo[skinId].limit = limit;
        index[skinId] = list.length;
        list.push(skinId);
    }
    
    function editSkinInfo(uint skinId,uint price, bool onSale,uint limit) external onlyOwner{
        require(skinInfo[skinId].price != 0 ,'not on sale');
        skinInfo[skinId].price = price;
        skinInfo[skinId].onSale = onSale;
        skinInfo[skinId].limit = limit;
    }
    
    function setOnSale(uint skinId,bool onSale) external onlyOwner{
        require(skinInfo[skinId].price != 0 ,'not on sale');
        skinInfo[skinId].onSale = onSale;
    }
    
    function changeLimit(uint skinId, uint limit) external onlyOwner{
        require(skinInfo[skinId].price != 0 ,'not on sale');
        skinInfo[skinId].limit = limit;
    }
    
    function checkOnSaleList() public view returns(uint[] memory out){
        uint amount;
        for(uint i = 0 ; i < list.length; i ++){
            if(skinInfo[list[i]].onSale){
                amount++;
            }
        }
        out = new uint[](amount);
        for(uint i = 0 ; i < list.length; i ++){
            if(skinInfo[list[i]].onSale){
                amount--;
                out[amount] = list[i];
            }
        }
    }
    
    function checkSkinList() public view returns(uint[] memory, uint[] memory){
        return(checkOnSaleList(),checkOnSalePrice());
    }
    
    function checkOnSalePrice() public view returns(uint[] memory out){
        uint[] memory _list = checkOnSaleList();
        out = new uint[](_list.length);
        for(uint i = 0; i < _list.length; i ++){
            out[i] = skinInfo[_list[i]].price;
        }
    }
    
    function coutingCost(uint skinId) public view returns(uint){
        uint price = skinInfo[skinId].price;
        return(price * 1e18 / getBVTPrice());
    }
    
    function buySkin(uint skinId, uint payWith) external{ // 1 for usdt 2 for bvt
        require(skinInfo[skinId].price != 0,'not on Sale');
        require(skinInfo[skinId].onSale,'not on sale');
        require(skinInfo[skinId].limit > skinInfo[skinId].totalBuy,'out of limit');
        require(payWith == 1 || payWith == 2,'wrong pay');
        uint price = skinInfo[skinId].price;
        if(payWith == 1){
            U.transferFrom(msg.sender,address(this),price);
        }else{
            BVT.transferFrom(msg.sender,address(this), coutingCost(skinId));
        }
        skin.mint(msg.sender,skinId);
    }
}