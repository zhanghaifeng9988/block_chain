pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

//父合约
contract A {
    uint256 public a;

    constructor() {
        a = 1;
    }
}

//子合约
contract B is A {
    uint256 public b;

    constructor() {
        b = 2;
    }
}
/* 1. 子合约 B 自动获得父合约 A 的所有非私有成员（状态变量和函数）;
2. 子合约可以扩展父合约的功能（添加新状态变量和函数）;
3. 子合约可以重写父合约的函数（使用 override 关键字） */