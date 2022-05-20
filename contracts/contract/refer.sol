// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../interface/ICOW721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
contract Refer is Ownable{
    IStable public stable;
    struct UserInfo{
        address invitor;
        uint referDirect;
        address[] referList; 
    }
    event Bond(address indexed player, address indexed invitor);
    mapping(address => UserInfo) public userInfo;
    
    function setStable(address addr) onlyOwner external{
        stable = IStable(addr);
    }
    
    function bondInvitor(address addr) external{
        require(stable.checkUserCows(addr).length > 0,'wrong invitor');
        require(userInfo[msg.sender].invitor == address(0),'had invitor');
        userInfo[addr].referList.push(msg.sender);
        userInfo[addr].referDirect++;
        userInfo[msg.sender].invitor = addr;
        emit Bond(msg.sender,addr);
    }
    
    function checkUserInvitor(address addr) external view returns(address){
        return userInfo[addr].invitor;
    }
    
    function checkUserReferList(address addr) external view returns(address[] memory){
        return userInfo[addr].referList;
    }
    
    function checkUserReferDirect(address addr) external view returns(uint){
        return userInfo[addr].referDirect;
    }
}