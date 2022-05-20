// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";


contract Market1155 is OwnableUpgradeable, ERC1155HolderUpgradeable{
    uint private _goodsId;
    // handle fee(percentage)
    uint public fee;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // define goods type
    mapping(uint => GoodsInfo) public goodsInfos;

    // support currency. by default,1 is main coin
    mapping(uint => address) public tradeType;

    //    mapping(uint => mapping(uint => goods)) public sellingGoods;
    mapping(uint => Goods) public sellingGoods;
    mapping(uint => mapping(address => uint[])) private _sellingList;

    mapping(uint => uint) private _sold;

    function init() public initializer {
        __Ownable_init();

        _goodsId = 1;
        fee = 2;
    }

    struct Goods {
        uint id;
        uint goodsType;
        uint tradeType;
        uint price;
        uint amount;
        address owner;
    }

    struct GoodsInfo {
        IERC1155Upgradeable place;
        string name;
    }


    event UpdateGoodsStatus(uint indexed goodsId, bool indexed status, uint goodsType, uint tokenId, uint amount, uint tradeType, uint price);
    event Exchanged(uint goodsId, uint goodsType, uint tokenId, uint amount, uint tradeType, uint price, address seller, address buyer);
    event NewGoods(uint goodsType, string name, address place);


    // ------------------------------  only owner ---------------------------------------
    function newTradeType(uint id_, address bank_) external onlyOwner returns (bool) {
        require(id_ > 1 && tradeType[id_] == address(0),"Wrong trade type");
        tradeType[id_] = bank_;
        return true;
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
        place:IERC1155Upgradeable(place_)
        });

        emit NewGoods(types_, name_, place_);
        return true;
    }

    function divestFee(address payable payee_, uint value_, uint tradeType_) external onlyOwner returns (bool){
        if (tradeType_ == 1) {
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

    function getGoodsId() external onlyOwner view returns (uint) {
        return _goodsId;
    }


    // ------------------------------  only owner end---------------------------------------

    function sell(uint goodsType_, uint tokenId_, uint amount_, uint tradeType_, uint price_) public {
        require(price_ >= 1e16 && price_ < 1e26, "Price");
        require(address(goodsInfos[goodsType_].place) != address(0) && amount_ > 0, "Wrong goods");

        if (tradeType_ != 1) {
            require(tradeType[tradeType_] != address(0), "Invalid trade type");
        }

        goodsInfos[goodsType_].place.safeTransferFrom(_msgSender(), address(this), tokenId_, amount_, "");

        sellingGoods[_goodsId] = Goods ({
        id : tokenId_,
        goodsType : goodsType_,
        tradeType : tradeType_,
        price : price_,
        amount : amount_,
        owner: _msgSender()
        });

        _sellingList[goodsType_][_msgSender()].push(tokenId_);

        emit UpdateGoodsStatus(_goodsId, true, goodsType_, tokenId_, amount_, tradeType_, price_);
        _goodsId += 1;
    }

    function cancelSell(uint goodsId_) public {
        require(sellingGoods[goodsId_].id != 0, "Invalid goodsId");

        Goods memory info = sellingGoods[goodsId_];
        uint arrLen = _sellingList[info.goodsType][_msgSender()].length;
        if (arrLen > 2) {
            for (uint i = 0; i + 1 < arrLen; i++) {
                if (_sellingList[info.goodsType][_msgSender()][i] == goodsId_) {
                    _sellingList[info.goodsType][_msgSender()][i] =  _sellingList[info.goodsType][_msgSender()][arrLen - 1];
                    break;
                }
            }
        }

        _sellingList[info.goodsType][_msgSender()].pop();
        goodsInfos[info.goodsType].place.safeTransferFrom(address(this), _msgSender(), info.id, info.amount, "");
        delete sellingGoods[goodsId_];

        emit UpdateGoodsStatus(goodsId_, false, info.goodsType, info.id, info.amount, 0, 0);
    }

    function mainCoinPurchase(uint goodsId_) public payable {
        Goods memory info = sellingGoods[goodsId_];
        require(info.id != 0 && info.tradeType == 1, "Main coin");
        require(info.price == msg.value, "Value");
        require(info.owner != _msgSender(), "Own");

        uint handleFee = info.price / 100 * fee;
        uint amount = info.price - handleFee;

        payable(address(this)).transfer(msg.value);
        payable(info.owner).transfer(amount);

        purchaseProcess(goodsId_, info.owner, info.goodsType, info.id, info.amount, info.tradeType, info.price);
    }

    function erc20Purchase(uint goodsId_) public {
        Goods memory info = sellingGoods[goodsId_];
        require(info.id != 0 && info.tradeType != 1, "erc20");
        require(info.owner != _msgSender(), "Own");

        uint handleFee =  info.price / 100 * fee;
        uint amount = info.price - handleFee;

        address banker = tradeType[info.tradeType];
        IERC20Upgradeable(banker).transferFrom(_msgSender(), info.owner, amount);
        IERC20Upgradeable(banker).transferFrom(_msgSender(), address(this), handleFee);

        purchaseProcess(goodsId_, info.owner, info.goodsType, info.id, info.amount, info.tradeType, info.price);
    }

    function purchaseProcess(uint goodsId_, address owner_, uint goodsType_, uint tokenId_, uint amount_, uint tradeType_, uint price_) internal {
        uint length = _sellingList[goodsType_][owner_].length;

        if (length > 2) {
            for (uint i = 0; i + 1 < length; i++) {
                if (_sellingList[goodsType_][owner_][i] == tokenId_) {
                    _sellingList[goodsType_][owner_][i] = _sellingList[goodsType_][owner_][length - 1];
                    break;
                }
            }
        }
        _sellingList[goodsType_][owner_].pop();

        goodsInfos[goodsType_].place.safeTransferFrom(address(this), _msgSender(), tokenId_, amount_, "");
        delete sellingGoods[goodsId_];
        _sold[goodsType_] += 1;

        emit Exchanged(goodsId_, goodsType_, tokenId_, amount_, tradeType_, price_, owner_, _msgSender());
    }


    function getSellingList(uint goodsType_, address addr_) public view returns (uint[] memory) {
        return _sellingList[goodsType_][addr_];
    }

    receive() external payable {}
}