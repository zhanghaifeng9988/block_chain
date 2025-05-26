// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.6.6;

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@uniswap/lib/contracts/libraries/SafeMath.sol';

// UniswapV2Library 库：提供了 Uniswap V2 所需的各种计算和辅助函数
library UniswapV2Library {
    using SafeMath for uint;

    // 返回排序后的代币地址（确保地址顺序一致性）
    // @param tokenA 代币A地址
    // @param tokenB 代币B地址
    // @return token0 较小的代币地址
    // @return token1 较大的代币地址
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // 计算交易对合约地址
    // @param factory 工厂合约地址
    // @param tokenA 代币A地址
    // @param tokenB 代币B地址
    // @return pair 交易对合约地址
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
            hex'ff',
            factory,
            keccak256(abi.encodePacked(token0, token1)),
            hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
        ))));
    }

    // 获取交易对的储备量
    // @param factory 工厂合约地址
    // @param tokenA 代币A地址
    // @param tokenB 代币B地址
    // @return reserveA 代币A的储备量
    // @return reserveB 代币B的储备量
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // 计算输出金额（给定精确的输入金额）
    // @param amountIn 输入金额
    // @param reserveIn 输入代币储备量
    // @param reserveOut 输出代币储备量
    // @return amountOut 输出金额
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997); // 0.3% 手续费
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // 计算输入金额（给定精确的输出金额）
    // @param amountOut 期望的输出金额
    // @param reserveIn 输入代币储备量
    // @param reserveOut 输出代币储备量
    // @return amountIn 需要的输入金额
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // 计算多跳路径的输出金额
    // @param factory 工厂合约地址
    // @param amountIn 输入金额
    // @param path 代币兑换路径
    // @return amounts[] 每一跳的金额数组
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // 计算多跳路径的输入金额
    // @param factory 工厂合约地址
    // @param amountOut 期望的输出金额
    // @param path 代币兑换路径
    // @return amounts[] 每一跳的金额数组
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}