// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.6.6;

// TransferHelper 库：提供了安全的代币转账方法
// 主要用于处理不同代币的转账操作，包括标准和非标准的 ERC20 代币
library TransferHelper {
    // 安全地发送 ETH
    // @param to 接收地址
    // @param value 发送数量
    function safeTransferETH(address to, uint value) internal {
        // 发送 ETH
        (bool success,) = to.call{value: value}('');
        // 确保转账成功
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }

    // 安全地转账 ERC20 代币
    // @param token 代币合约地址
    // @param to 接收地址
    // @param value 转账数量
    function safeTransfer(address token, address to, uint value) internal {
        // 调用代币合约的 transfer 方法
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        // 确保调用成功且返回值为 true（如果有返回值）
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper: TRANSFER_FAILED'
        );
    }

    // 安全地从指定地址转账 ERC20 代币
    // @param token 代币合约地址
    // @param from 转出地址
    // @param to 接收地址
    // @param value 转账数量
    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // 调用代币合约的 transferFrom 方法
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        // 确保调用成功且返回值为 true（如果有返回值）
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper: TRANSFER_FROM_FAILED'
        );
    }

    // 安全地批准 ERC20 代币的使用权限
    // @param token 代币合约地址
    // @param spender 被授权地址
    // @param value 授权数量
    function safeApprove(address token, address spender, uint value) internal {
        // 调用代币合约的 approve 方法
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, spender, value)
        );
        // 确保调用成功且返回值为 true（如果有返回值）
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper: APPROVE_FAILED'
        );
    }
}