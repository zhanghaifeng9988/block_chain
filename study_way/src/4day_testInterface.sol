pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

//接口
interface ICounter {
    function count()  external view returns (uint);
    function increment() external;
}

//合约用来实现接口：实现了接口中声明的所有方法（否则会编译错误）
contract Counter is ICounter {
    //count 变量是 public 的，所以会自动生成一个同名的 getter 函数（满足 count() 接口要求）
    uint  public count;

    function increment() external {
        count += 1;
    }
}

//与合约Counter交互
contract MyContract {
    function incrementCounter(address  _counter)  external {
        //将传入的参数地址，转换为 ICounter 类型，并调用其 increament() 方法
        ICounter(_counter).increment();
    }

    function getCount(address _counter) external view returns (uint) {
        ////将传入的参数地址，转换为 ICounter 类型，并调用其 count() 方法
        return ICounter(_counter).count();
    }

}