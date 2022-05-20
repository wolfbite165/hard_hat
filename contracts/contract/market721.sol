// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";

contract Market721 is OwnableUpgradeable, ERC721HolderUpgradeable{
    uint private _goodsSeq;
    // handle fee(percentage)
    uint public fee;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // define goods type
    mapping(uint => GoodsInfo) public goodsInfos;

    // support currency. by default,1 is main coin
    mapping(uint => address) public tradeType;

    mapping(uint => mapping(uint => Goods)) public sellingGoods;
    mapping(uint => mapping(address => uint[])) private _sellingList;

    mapping(uint => uint) public _sold;


    function init() public initializer {
        __Ownable_init();

        _goodsSeq = 1;
        fee = 2;
    }

    struct Goods {
        uint id;
        uint tradeType;
        uint price;
        address owner;
    }

    struct GoodsInfo {
        ERC721Upgradeable place;
        string name;
    }


    event UpdateGoodsStatus(uint indexed goodsId, bool indexed status, uint goodsType, uint tokenId, uint tradeType, uint price, address seller);
    event Exchanged(uint goodsId, uint goodsType, uint tokenId, uint tradeType, uint price, address seller, address buyer);
    event NewGoods(uint goodsType, string name, address place);


    // ------------------------------  only owner ---------------------------------------
    function newTradeType(uint id_, address bank_) external onlyOwner returns (bool) {
        require(id_ != 3 && tradeType[id_] == address(0),"Wrong trade type");
        tradeType[id_] = bank_;
        return true;
    }

    function changeTradeType(uint id_, address bank) external onlyOwner  {
        require(id_ != 3 && tradeType[id_] != address(0),"Wrong change type");
        tradeType[id_] = bank;
    }


    function changeFee(uint fee_) external onlyOwner returns (bool) {
        require(fee_ > 0 && fee_ != fee,"Invalid fee");
        fee = fee_;
        return true;
    }

    function newGoodsInfo(uint types_, address place_, string memory name_) external onlyOwner returns (bool) {
        require(place_ != address(0) && address(goodsInfos[types_].place) == address(0), "New goods");

        goodsInfos[types_] = GoodsInfo({
        name:name_,
        place:ERC721Upgradeable(place_)
        });

        emit NewGoods(types_, name_, place_);
        return true;
    }

    function divestFee(address payable payee_, uint value_, uint tradeType_) external onlyOwner returns (bool){
        if (tradeType_ == 3) {
            payee_.transfer(value_);
            return true;
        }
        require(tradeType[tradeType_] != address(0), "Divest type");
        address bank = tradeType[tradeType_];
        IERC20Upgradeable(bank).safeTransfer(payee_, value_);
        return true;
    }

    function queryGoodsSoldData(uint types_) external onlyOwner view returns (uint) {
        return _sold[types_];
    }

    function getGoodsSeq() external onlyOwner view returns (uint) {
        return _goodsSeq;
    }

    function cleanSaleList(address addr, uint32 goodsType ) public onlyOwner {
        delete _sellingList[goodsType][addr];
    }



    // ------------------------------  only owner end---------------------------------------

    function sell(uint goodsType_, uint tokenId_, uint tradeType_, uint price_) public {
        require(price_ < 1e26 && price_ % 1e15 == 0, "Price");
        require(address(goodsInfos[goodsType_].place) != address(0), "Wrong goods");

        if (tradeType_ != 3) {
            require(tradeType[tradeType_] != address(0), "Invalid trade type");
        }

        goodsInfos[goodsType_].place.safeTransferFrom(_msgSender(), address(this), tokenId_);

        sellingGoods[goodsType_][tokenId_] = Goods ({
        id : _goodsSeq,
        tradeType : tradeType_,
        price : price_,
        owner: _msgSender()
        });

        _sellingList[goodsType_][_msgSender()].push(tokenId_);
        emit UpdateGoodsStatus(_goodsSeq, true, goodsType_, tokenId_, tradeType_, price_, _msgSender());
        _goodsSeq += 1;
    }

    function cancelSell(uint goodsType_, uint tokenID) public {
        uint arrLen = _sellingList[goodsType_][_msgSender()].length;
        bool exist;
        uint idx;
        for (uint i = 0; i < arrLen; i++) {
            if (_sellingList[goodsType_][_msgSender()][i] == tokenID) {
                exist = true;
                idx = i;
                break;
            }
        }

        require(exist, "invalid token ID");
        if (arrLen > 1 && idx < arrLen - 1) {
            _sellingList[goodsType_][_msgSender()][idx] = _sellingList[goodsType_][_msgSender()][arrLen - 1];
        }

        _sellingList[goodsType_][_msgSender()].pop();
        goodsInfos[goodsType_].place.safeTransferFrom(address(this), _msgSender(), tokenID);

        uint goodsId = sellingGoods[goodsType_][tokenID].id;
        delete sellingGoods[goodsType_][tokenID];

        emit UpdateGoodsStatus(goodsId, false, goodsType_, tokenID, 0, 0, address(0));
    }

    function mainCoinPurchase(uint goodsType_, uint tokenId_) public payable {
        Goods memory info = sellingGoods[goodsType_][tokenId_];
        require(info.id > 0, "Not selling");
        require(info.tradeType == 3, "Main coin");

        require(info.price == msg.value, "Value");
        require(info.owner != _msgSender(), "Own");

        uint handleFee = info.price / 100 * fee;
        uint amount = info.price - handleFee;
        payable(info.owner).transfer(amount);

        purchaseProcess(info.id, info.owner, goodsType_, tokenId_, info.tradeType, info.price);
    }

    function erc20Purchase(uint goodsType_, uint tokenId_) public {
        Goods memory info = sellingGoods[goodsType_][tokenId_];

        require(info.id > 0, "Not selling");
        require(info.tradeType != 3, "erc20");
        require(info.owner != _msgSender(), "Own");

        uint handleFee =  info.price / 100 * fee;
        uint amount = info.price - handleFee;

        address banker = tradeType[info.tradeType];
        IERC20Upgradeable(banker).safeTransferFrom(_msgSender(), info.owner, amount);
        IERC20Upgradeable(banker).safeTransferFrom(_msgSender(), address(this), handleFee);

        purchaseProcess(info.id, info.owner, goodsType_, tokenId_, info.tradeType, info.price);
    }

    function purchaseProcess(uint goodsId_, address owner_, uint goodsType_, uint tokenId_, uint tradeType_, uint price_) internal {
        popToken(goodsType_, owner_, tokenId_);

        goodsInfos[goodsType_].place.safeTransferFrom(address(this), _msgSender(), tokenId_);
        delete sellingGoods[goodsType_][tokenId_];
        _sold[goodsType_] += 1;

        emit Exchanged(goodsId_, goodsType_, tokenId_, tradeType_, price_, owner_, _msgSender());
    }

    function popToken(uint goodsType_, address owner_, uint tokenID) internal{
        uint length = _sellingList[goodsType_][owner_].length;
        uint lastIdx = length - 1;
        for (uint i = 0; i < lastIdx; i++) {
            if (_sellingList[goodsType_][owner_][i] == tokenID) {
                _sellingList[goodsType_][owner_][i] = _sellingList[goodsType_][owner_][lastIdx];
                break;
            }
        }
        _sellingList[goodsType_][owner_].pop();
    }

    function getUserSaleList(uint goodsType_, address addr_) public view returns (uint[3][] memory data) {
        uint len = _sellingList[goodsType_][addr_].length;
        data = new uint[3][](len);
        for (uint i = 0; i < len; i++) {
            uint[3] memory saleGoods;
            uint tokenId = _sellingList[goodsType_][addr_][i];
            saleGoods[0] = tokenId;
            saleGoods[1] = sellingGoods[goodsType_][tokenId].tradeType;
            saleGoods[2] = sellingGoods[goodsType_][tokenId].price;
            data[i] = saleGoods;
        }
    }

    function getUserSaleTokenId(uint goodsType_,address addr) public view returns(uint[] memory data) {
        return _sellingList[goodsType_][addr];
    }

    receive() external payable {}
}