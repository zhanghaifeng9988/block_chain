 // 原有合约：Counter
// 需求：升级 Counter 合约
// 具体步骤：
// 部署代理合约 CounterProxy，并将初始的实现合约地址（Counter 合约的地址）传入。
// 部署升级后的合约 CounterV2。
// 通过 CounterProxy 合约调用 upgradeTo(address _impl) 函数，将实现合约地址更新为 CounterV2 合约的地址。
// 这样，CounterProxy 合约就会代理到 CounterV2 合约，实现功能的升级，而合约地址保持不变。

// 那这种是理想状态，counter合约虽然被部署了，但是没有启用，没有数据，才可以这么做，
// 如果有数据，那就不能这么做了
 
 //SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Counter {
    // address public impl;
    uint public counter;

    function add(uint256 i) public {
        counter += 1;
    }

    function get() public view returns(uint) {
        return counter;
    }

    function uintToBytes32(uint i) external view returns (bytes32 data) {
        data = bytes32(i);
    }

    function read(bytes32 slot) external  view returns(bytes32 data){
            assembly {
                data := sload(slot) // load from store    
            }
    }

    function write(bytes32 slot,uint256 value) external {
            assembly{
                sstore(slot,value)
            }
    }
}

contract CounterV2 {
    // address public impl;
    uint public counter;

    function add(uint256 i) public {
        counter += i;
    }

    function get() public view returns(uint) {
        return counter;
    }
}
/*
contract CounterProxy  {
    uint public counter;
    address public impl;   // impl + 2

    constructor(address _impl) {
        impl = _impl;
    }

    function upgradeTo(address _impl) public {
        impl = _impl;
    }

    // 分别代理到 Counter
    function add(uint256 n) external {
        bytes memory callData = abi.encodeWithSignature("add(uint256)", n);
        (bool ok,) = address(impl).delegatecall(callData);
        if(!ok) revert("Delegate call failed");
    }

    function get() external returns(uint256) {
        bytes memory callData = abi.encodeWithSignature("get()");
        (bool ok, bytes memory retVal) = address(impl).delegatecall(callData);

        if(!ok) revert("Delegate call failed");

        return abi.decode(retVal, (uint256));
    }
} */




// 如果counter合约已经有数据了，需要这么做
contract CounterProxy {
    uint public counter;  // 添加counter变量
    address public impl;

    constructor(address _impl) {
        impl = _impl;
        // 从Counter合约读取初始值
        (bool ok, bytes memory retVal) = address(_impl).staticcall(
            abi.encodeWithSignature("get()")
        );
        if(ok) {//将初始合约得状态变量，迁移到代理合约得状态变量中
            counter = abi.decode(retVal, (uint));
        }
    }

    function upgradeTo(address _impl) public {
        impl = _impl;
    }

    function add(uint256 n) external {
        bytes memory callData = abi.encodeWithSignature("add(uint256)", n);
        (bool ok,) = address(impl).delegatecall(callData);
        if(!ok) revert("Delegate call failed");
    }

    function get() external  returns(uint256) {
        bytes memory callData = abi.encodeWithSignature("get()");
        (bool ok, bytes memory retVal) = address(impl).delegatecall(callData);

        if(!ok) revert("Delegate call failed");

        return abi.decode(retVal, (uint256));
    }
}