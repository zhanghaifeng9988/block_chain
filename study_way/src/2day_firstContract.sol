pragma  solidity ^0.8.9;
// SPDX-License-Identifier: MIT
// 第1个合约

contract Counter {
    // 状态变量 counter
    uint256 public  counter;

    // 构造函数，初始化 counter 的值为 0
    constructor() {
        counter = 0;
    }

    // get() 方法：获取 counter 的值
    function get() public view returns (uint256) {
        return counter;
    }

    // add(x) 方法：给 counter 变量加上 x
    function add(uint256 x) public {
        counter += x;
    }
}

