// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

contract Relationship is OwnableUpgradeable{
    using StringsUpgradeable for uint256;
    // mapping(address => mapping(uint => address)) public applys;//1 for friend, 2 for lover, 3 for bestie, 4 for confidant, 5 for bro
    // mapping(address => mapping(uint => address)) public relation;
    // mapping(address => mapping(uint => uint)) public relationAmount;
    mapping(address => mapping(address => uint)) public relationTypes;
    // mapping(uint => uint) public limit;
    struct UserInfo{
        uint gender;
        mapping(uint => address[]) relationGroup;
    }
    mapping(address => UserInfo) public userInfo;
    address public banker;
    event ApplyRelationship(address indexed player, address indexed target, uint indexed types);
    event AcceptRelationship(address indexed player, address indexed traget, uint indexed types);
    event BondRelationship(uint indexed relationshipID, string indexed couple, uint indexed types);

    mapping(string => uint) relationIdentify;
    uint public rid;

    function initialize() public initializer{
        __Context_init_unchained();
        __Ownable_init_unchained();

        rid = 1;
    }

    function bond(address[2] memory addr,uint types, bytes32 r, bytes32 s, uint8 v) public {
        bytes32 hash = keccak256(abi.encodePacked(addr, types));
        address a = ecrecover(hash, v, r, s);
        require(a == banker, "not banker");
        require(addr[1] != addr[0],'wrong address');
        require(types > 0 && types <= 5,'wrong type');
        relationTypes[addr[0]][addr[1]] = types;
        relationTypes[addr[1]][addr[0]] = types;

        string memory rkey = relationshipKey(addr);
        emit BondRelationship(rid,rkey,types);

        relationIdentify[rkey] = rid;
        rid += 1;
    }


    function relationshipKey(address[2] memory addr) public pure returns(string memory ){
        address [2] memory a;
        if (uint256(uint160(addr[0])) > uint256(uint160(addr[1]))) {
            a[0] = addr[0];
            a[1] = addr[1];
        } else {
            a[0] = addr[1];
            a[1] = addr[0];
        }
        return string(abi.encodePacked(uint256(uint160(addr[0])).toHexString(),"#",uint256(uint160(addr[1])).toHexString()));
    }
}