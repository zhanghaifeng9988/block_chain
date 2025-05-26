// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.6.6;

import './interfaces/IUniswapV2Factory.sol';
import './libraries/TransferHelper.sol';
import './interfaces/IUniswapV2Router02.sol';
import './libraries/UniswapV2Library.sol';
import './libraries/SafeMath.sol';
import './interfaces/IERC20.sol';
import './interfaces/IWETH.sol';

// UniswapV2Router02 合约：实现了与用户交互的所有主要功能
contract UniswapV2Router02 is IUniswapV2Router02 {
    // 使用 SafeMath 库进行安全的数学运算
    using SafeMath for uint;

    // 状态变量：工厂合约地址
    address public immutable override factory;
    // 状态变量：WETH 合约地址
    address public immutable override WETH;

    // 修饰器：确保操作在截止时间之前完成
    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'UniswapV2Router: EXPIRED');
        _;
    }

    // 构造函数：设置工厂合约和 WETH 地址
    constructor(address _factory, address _WETH) public {
        factory = _factory;
        WETH = _WETH;
    }

    // 接收 ETH 的回退函数
    receive() external payable {
        // 确保只接收来自 WETH 合约的 ETH
        assert(msg.sender == WETH);
    }
}