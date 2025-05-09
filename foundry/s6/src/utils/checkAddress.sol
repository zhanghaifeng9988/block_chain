pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

//检查是否是合约地址
library AddressUtils {
    function isContract(address _addr) internal view returns (bool) {
        uint32 size;
        assembly {//内联汇编代码块。Solidity允许在合约中嵌入EVM汇编代码，用于执行一些低级操作。
            size := extcodesize(_addr)//EVM操作码，用于获取目标地址 _addr 的代码大小（以字节为单位）
        }
        return (size > 0);
    }
}

