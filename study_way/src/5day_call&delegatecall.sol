pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

contract Counter {
    uint public counter;
    address public sender;

    // 修正事件声明，明确参数类型
    event FallbackCalled(address indexed sender, bytes data);

    function count() public {
        counter += 1;
        sender = msg.sender;
    }

    // 显式接收 ETH 的函数
    receive() external payable {}

    // 处理未知调用
    fallback() external payable {
        // 自定义逻辑（例如转发调用或记录事件）
        emit FallbackCalled(msg.sender, msg.data);
    }
}

contract CallTest {
    uint public counter;
    address public sender;

    //调用逻辑：直接调用Counter合约的count()函数
    //调用结果：Counter合约的： counter+1，sender更新为CallTest合约地址
    function callCount(Counter c) public {
        c.count();
    }

    //调用逻辑：让Counter的count()代码在CallTest环境中执行
    //调用结果：CallTest合约的：  counter+1，sender更新为CallTest合约地址
    function lowDelegatecallCount(address  addr) public {
        //用于生成函数调用的ABI编码数据,返回bytes类型的编码结果,bytes 是动态字节数组类型
        bytes memory methodData = abi.encodeWithSignature("count()");
        //delegatecall需要原始ABI编码数据作为输入
        (bool success, ) =addr.delegatecall(methodData);
        require(success, "Delegatecall failed"); // 如果失败，回滚交易
    }

    //调用逻辑：通过call调用Counter合约的count()函数
    //调用结果：Counter合约的:  counter+1，sender更新为CallTest合约地址
    function lowCallCount(address addr) public {
        bytes memory methodData =abi.encodeWithSignature("count()");
        (bool success, ) =addr.call(methodData);
        require(success, "Delegatecall failed");
        // addr.call{gas:1000}(methodData);
        // addr.call{gas:1000, value: 1 ether}(methodData);
    }

    //call 和 传入合约类型参数直接调用得结果一样
    //delegatecall调用得合约可以比做是类库，调用结果影响当前合约得状态

}

