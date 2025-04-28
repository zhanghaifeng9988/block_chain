// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

//下面的合约实现了一个最简单的加密货币
//币确实可以无中生有地产生，但是只有创建合约的人才能做到（实现一个不同的发行计划也不难）。
//任何人都可以给其他人转币，不需要注册用户名和密码 —— 所需要的只是以太坊密钥对。

contract Coin {
    // address 类型的公共变量,关键字“public”让这些变量可以从外部读取
    // address 类型是一个160位的值，且不允许任何算数操作。这种类型适合存储合约地址或外部人员的密钥对。
    address public minter;
    //mapping 引用类型 是一种键值对存储结构,作用是高效地通过键（Key）查找对应的值（Value）
    //用于存储每个地址的余额
    mapping(address => uint256) public balances;

    // 轻客户端可以通过事件，针对变化作出高效的反应
    event Sent(address from, address to, uint256 amount);

    // 这是构造函数，只有当合约创建时运行
    constructor() {
        //msg.sender表示当前合约的创建者的地址。在构造函数中，minter 存储创建合约的人的地址。
        minter = msg.sender;
    }

    // 如果 mint 被合约创建者外的其他人调用，则什么也不会发生
    // 如果调用mint函数的是合约的创建者，那么就可以用来管理用户的余额，就是铸造代币的数量
    function mint(address receiver, uint256 amount) public {
        if (msg.sender != minter) return;
        balances[receiver] += amount; //将铸造的金额（amount）加到接收者的余额（balances[receiver]）上
    }

    // send 函数可被任何人用于向他人发送币 (当然，前提是发送者拥有符合数量的币)。
    function send(address receiver, uint256 amount) public {
        if (balances[msg.sender] < amount) return;
        balances[msg.sender] -= amount;
        balances[receiver] += amount;
        emit Sent(msg.sender, receiver, amount);
    }
}

