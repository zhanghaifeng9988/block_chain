pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

contract Foo {
    function myFunc(uint x) public pure returns (uint) {
        require(x != 0,"if equal 0,require failed");
        assert(x <=100);// 如果 x > 100，触发 Panic 错误，会被第二个 catch 捕获
        return x + 1;
    }
}


contract trycatch {

    Foo  public foo;
    uint public y;
    string public errorMessage;
    constructor() {
        foo = new Foo();
    }


    function tryCatchExtenalCall(uint i) public {

        try foo.myFunc(i) returns (uint result) {
            y = result;//返回值会被赋值给 result
        }


        catch Error(string memory reason) {
            //捕获Foo中的require失败的错误，捕获revert("error message")
            //errorMessage = reason;
            revert(reason); // 中断交易并返回错误信息
        }


        //捕获：assert 失败，算术错误（如除以零、数组越界），其他低级别错误：如 Gas 不足、调用不存在的函数等。
        //错误信息是低级别的 bytes 数据（通常是编码后的错误标识符）。
        //适合处理非预期的严重错误（如合约内部逻辑错误）。
        catch (bytes memory  lowLevelData ){
            // //
             errorMessage = string(abi.encodePacked("Low-level error: ", lowLevelData));
             revert(errorMessage); // 强制外部交易回滚
            //revert("Low-level error"); // 中断交易
        }
    }
}
