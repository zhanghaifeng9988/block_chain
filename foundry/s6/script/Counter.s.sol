// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Counter} from "../src/Counter.sol";


contract CounterScript is Script {
    Counter public counter;

    function setUp() public {} //初始化

    function run() public { //脚本执行入口
        vm.startBroadcast(); // 开始记录交易

        counter = new Counter();// 部署新合约实例
        // 输出部署地址
        console.log('Counter deployed on %s',address(counter));

        // saveContract("Counter",address(counter));

        // 调用合约方法初始化数据-- 部署时执行
        counter.setNumber(10);
        // 调用合约方法增加数据-- 部署时执行
        counter.increment();
        // 结束交易记录
        vm.stopBroadcast();
    }
}
