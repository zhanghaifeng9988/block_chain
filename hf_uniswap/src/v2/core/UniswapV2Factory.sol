// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.6.6;

import './UniswapV2Pair.sol';
import '../interfaces/IUniswapV2Factory.sol';

// UniswapV2Factory 合约：Uniswap V2 的工厂合约，负责创建和管理所有交易对
// 实现了 IUniswapV2Factory 接口
contract UniswapV2Factory is IUniswapV2Factory {
    // 状态变量：协议费用接收地址
    // 当设置了该地址时，协议会收取 1/6 的手续费（占总手续费的 1/6，即 0.05%）
    address public feeTo;
    
    // 状态变量：费用设置权限地址
    // 该地址有权限修改 feeTo 地址和 feeToSetter 地址
    address public feeToSetter;

    // 状态变量：双重映射，存储代币对到其对应的交易对合约地址
    // 映射结构：token0 地址 => token1 地址 => 交易对合约地址
    mapping(address => mapping(address => address)) public getPair;
    
    // 状态变量：数组，存储所有已创建的交易对合约地址
    // 用于追踪和遍历所有交易对
    address[] public allPairs;

    // 事件：在 interface 中定义
    // event PairCreated：当创建新的交易对时触发
    // 参数：token0 - 第一个代币地址（较小的地址）
    //      token1 - 第二个代币地址（较大的地址）
    //      pair - 新创建的交易对合约地址
    //      allPairs.length - 当前交易对总数

    // 构造函数：初始化工厂合约
    // 参数：_feeToSetter - 初始费用设置权限地址
    constructor(address _feeToSetter) public {
        feeToSetter = _feeToSetter;
    }

    // 函数：获取当前所有已创建的交易对数量
    // 返回：uint - 交易对总数
    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }

    // 函数：创建新的交易对
    // 参数：tokenA - 第一个代币地址
    //      tokenB - 第二个代币地址
    // 返回：pair - 新创建的交易对合约地址
    function createPair(address tokenA, address tokenB) external returns (address pair) {
        // 检查：确保两个代币地址不相同
        require(tokenA != tokenB, 'UniswapV2: IDENTICAL_ADDRESSES');
        
        // 将代币地址按大小排序，确保相同的代币对无论传入顺序如何都会得到相同的结果
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        
        // 检查：确保 token0 地址不为零地址
        require(token0 != address(0), 'UniswapV2: ZERO_ADDRESS');
        
        // 检查：确保该交易对尚未创建
        require(getPair[token0][token1] == address(0), 'UniswapV2: PAIR_EXISTS');
        
        // 获取 UniswapV2Pair 合约的创建字节码
        bytes memory bytecode = type(UniswapV2Pair).creationCode;
        
        // 计算用于 create2 的 salt 值：token0 和 token1 地址的哈希
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        
        // 使用 create2 操作码部署新的交易对合约
        // create2 确保了给定相同的 token0 和 token1，总是会生成相同的合约地址
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        
        // 调用新创建的交易对合约的初始化函数
        // 设置交易对的两个代币地址
        IUniswapV2Pair(pair).initialize(token0, token1);
        
        // 在状态变量中记录交易对映射关系（双向记录）
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair;
        
        // 将新创建的交易对地址添加到数组中
        allPairs.push(pair);
        
        // 触发交易对创建事件
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    // 函数：设置协议费用接收地址
    // 参数：_feeTo - 新的费用接收地址
    // 权限：仅 feeToSetter 可调用
    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
        feeTo = _feeTo;
    }

    // 函数：转移费用设置权限
    // 参数：_feeToSetter - 新的费用设置权限地址
    // 权限：仅当前 feeToSetter 可调用
    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }
}