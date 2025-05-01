pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

contract Foo {
    function myFunc(uint x) public pure returns (uint) {
        require(x != 0, "if equal 0, require failed");
        assert(x <= 100); // 如果 x > 100，触发 Panic 错误
        return x + 1;
    }
}

contract TryCatch {
    Foo public foo;
    uint public y;
    
    // 定义错误事件
    event ErrorOccurred(string errorType, string reason, bytes lowLevelData);
    
    constructor() {
        foo = new Foo();
    }

    function tryCatchExternalCall(uint i) public {
        try foo.myFunc(i) returns (uint result) {
            y = result; // 成功时更新状态
        } catch Error(string memory reason) {
            // 记录require/revert错误
            emit ErrorOccurred("Require/Revert Error", reason, "");
            revert(reason); // 仍然回滚交易并返回错误信息
        } catch (bytes memory lowLevelData) {
            // 记录assert/panic错误
            string memory errorMsg = "Low-level error occurred";
            emit ErrorOccurred("Assert/Panic Error", errorMsg, lowLevelData);
            revert(errorMsg); // 仍然回滚交易并返回错误信息
        }
    }
}