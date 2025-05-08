// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
//导入待测试得合约
import {Counter} from "../src/Counter.sol";

contract CounterTest is Test {
    //声明一个 Counter 类型的公共状态变量 counter，用于在测试中操作合约实例。
    Counter public counter;

    function setUp() public {//测试初始化
        counter = new Counter();//部署一个新的 Counter 合约实例。
        counter.setNumber(0);//调用合约的 setNumber 方法，将计数器初始值设为 0。
    }

    //测试用例 1
    function test_Increment() public {
        counter.increment();
        //断言 counter.number() 的返回值等于 1
        assertEq(counter.number(), 1);
        //打印当前区块号（用于调试，不影响测试逻辑）。
        console.log("Block number", block.number);
    }

    ////测试用例 2  自动生成随机输入 x 测试边界条件。
    function testFuzz_SetNumber(uint256 x) public {
        //将计数器数值设为随机值 x
        counter.setNumber(x);
        //断言设置后的值等于 x
        assertEq(counter.number(), x);
    }
}

