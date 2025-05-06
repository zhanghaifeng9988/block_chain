// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//导入了 OpenZeppelin 库中的 ERC20 标准合约实现，OpenZeppelin 是经过审计的安全智能合约库。
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

//定义了一个名为 XuXu 的合约，它继承自 OpenZeppelin 的 ERC20 合约，获得了所有标准 ERC20 功能。
contract XuXu is ERC20 {
    //接收一个 initialSupply 参数表示初始发行量
//调用父合约 ERC20 的构造函数，设置代币名称为 "XuXu"，符号为 "XX"
    constructor(uint256 initialSupply) ERC20("XuXu", "XX") {
        _mint(msg.sender, initialSupply * 10 ** decimals());
    }
    //_mint 是 ERC20 的内部函数，用于创建新代币

// 将所有初始代币铸造给部署者 (msg.sender)

// initialSupply * 10 ** decimals() 将输入的单位转换为代币的最小单位（考虑小数位数）
}