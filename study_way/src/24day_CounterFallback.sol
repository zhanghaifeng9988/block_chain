pragma solidity ^0.8.0;
 //SPDX-License-Identifier: UNLICENSED
//高级代理模式代码

//存储槽管理：
//这是一个库，用于管理存储槽
// AddressSlot结构体用于存储地址值
// getAddressSlot函数,,通过assembly直接操作存储槽
// 使用storage关键字确保返回的是存储引用
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    function getAddressSlot(
        bytes32 slot
    ) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

contract Counter {
    uint private counter;

    function add(uint256 i) public {
        counter += 1;
    }

    function get() public view returns(uint) {
        return counter;
    }
}

contract CounterV2 {
    uint private counter;
    uint public counter2;
    

    function add(uint256 i) public {
        counter += i;
    }

    function get() public view returns(uint) {
        return counter;
    }

    function add2(uint256 i) public {
        counter2 += i;
    }

    function get2() public view returns(uint) {
        return counter2;
    }


    function upgradesdgasTo(address _implementation) external {

    }

    
}

 //  代理合约
contract CounterProxy {
    
    //解决存储槽冲突问题，使用特定的存储槽来存储实现合约地址，避免了与实现合约的存储冲突
    //减1是为了避免哈希冲突
    bytes32 private constant IMPLEMENTATION_SLOT =
        bytes32(uint(keccak256("eip1967.proxy.implementation")) - 1);
    //eip1967.proxy.implementation - 用于存储实现合约地址
    //eip1967.proxy.admin - 用于存储管理员地址
    //eip1967.proxy.beacon - 用于存储beacon合约地址


    constructor() {
    }

    //通用代理机制：可以代理任何函数调用,不需要为每个函数都写代理代码
    function _delegate(address _implementation) internal virtual {
        assembly {//assembly 可以直接操作内存和存储槽
        // 复制调用数据到内存
            calldatacopy(0, 0, calldatasize())

        // 执行delegatecall，在代理合约的上下文中执行实现合约的代码
            let result := delegatecall(
            gas(),                // 传递所有gas
             _implementation,     // 实现合约地址
             0,                   // 输入数据在内存中的位置
             calldatasize(),      // 输入数据大小
             0,                   // 输出数据在内存中的位置
             0                    // 输出数据大小
             ) 

             // 复制返回数据到内存
            returndatacopy(0, 0, returndatasize())

            // 处理结果
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    // 回退函数：
    //fallback函数处理所有未定义的函数调用
    // receive函数处理ETH转账
    //都通过_delegate转发到实现合约
    function _fallback() private {
        _delegate(_getImplementation());
    }

    fallback() external payable {
        _fallback();
    }

    receive() external payable {
        _fallback();
    }


    // 实现合约：

    // _getImplementation获取当前实现合约地址
    function _getImplementation() private view returns (address) {
        return StorageSlot.getAddressSlot(IMPLEMENTATION_SLOT).value;
    }

    //_setImplementation设置新的实现合约地址
    //检查新实现合约是否有效
    function _setImplementation(address _implementation) private {
        require(_implementation.code.length > 0, "implementation is not contract");
        StorageSlot.getAddressSlot(IMPLEMENTATION_SLOT).value = _implementation;
    }


    //upgradeTo是公开的升级接口
    //升级机制：可以安全地升级到新版本,新版本可以添加新的状态变量和函数
    function upgradeTo(address _implementation) external {
        _setImplementation(_implementation);
    }

}

//***总体理解：
// fallback模式，它通过以下机制实现更高级的代理功能：
// 实现合约地址管理：
// 将实现合约地址引入代理合约
// 使用特定的存储槽（IMPLEMENTATION_SLOT）来存储这个地址
// 通过StorageSlot库，安全地管理存储
// 代理转发机制：
// 通过_delegate函数调用实现合约中的状态变量和函数
// 在代理合约的上下文中执行实现合约的代码
// 处理执行结果并返回
// 升级机制：
// 通过_getImplementation获取当前实现合约地址
// 使用_setImplementation函数设定新的实现合约
// 通过调用upgradeTo函数实现合约升级
// 这种模式比最初的代理模式更灵活、更安全，能够实现无缝的合约升级。


//***重点剖析：
// 状态变量的存储位置：
// 所有状态变量都存储在代理合约的存储中：IMPLEMENTATION_SLOT
// 当使用delegatecall时，实现合约的代码在代理合约的上下文中执行
// 实现合约中的状态变量访问会映射到代理合约的存储中
// 代理合约不需要显式定义这些变量，它们是通过delegatecall动态映射的



//***状态变量对齐规则：
// 新合约必须保持原有状态变量的顺序和类型
// 原有变量必须使用相同的存储槽
// 新变量必须添加在原有变量之后



// 优点：
// 可以无限次升级
// 可以添加新的状态变量
// 可以添加新的函数
// 存储布局更安全
// 不需要修改代理合约代码
// 这就是为什么这个实现更适合复杂的升级场景。


