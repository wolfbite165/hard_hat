// SPDX-License-Identifier: MIT
pragma solidity = 0.8.4;
interface IBEP20 {
    function decimals() external view returns (uint8);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint amount) external returns (bool);

    function mint(address addr_, uint amount_) external;

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}