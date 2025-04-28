// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;//源代码使用Solidity版本，但不包括 0.9.0 或更高版本
//关键字 pragma:编译指令,是告知编译器如何处理源代码的指令的


contract SimpleStorage {
    uint storedData;
//可修改storedData状态的函数
    function set(uint x) public {
        storedData = x;
    }
//定义一个不修改合约状态,且返回无符号整数（uint）的函数
    function get() public view returns (uint) {
        return storedData;
    }
//函数 set 和 get 可以用来变更或取出变量的值。
}

/* 这个合约，它能允许任何人在合约中存储一个单独的数字，
并且这个数字可以被世界上任何人访问，
且没有可行的办法阻止你发布这个数字。 */

/* 当然，任何人都可以再次调用 set ，传入不同的值，覆盖你的数字，
在以太坊区块链上，每次成功调用 set 函数修改 storedData 的值时，
这个状态变更会被记录在区块链中，并且是不可篡改的
 */


