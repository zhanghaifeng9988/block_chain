// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.6.6;

// UQ112x112 库：用于处理 224 位定点数运算
// Q112 表示使用 112 位来表示小数部分
// 主要用于价格计算，可以精确表示很小的价格比率
library UQ112x112 {
    // 224 位整数中，前 112 位用于整数部分，后 112 位用于小数部分
    uint224 constant Q112 = 2**112;

    // 将 uint112 转换为 UQ112x112
    // @param y 要转换的 uint112 数值
    // @return z 转换后的 UQ112x112 数值（将输入值左移 112 位）
    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112; // 不会溢出，因为最大的 y 是 2^112-1
    }

    // 将 UQ112x112 除以 uint112
    // @param x UQ112x112 格式的被除数
    // @param y uint112 格式的除数
    // @return z 商，仍然是 UQ112x112 格式
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }
}