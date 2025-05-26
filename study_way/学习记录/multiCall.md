# 以太坊基本情况和显示需求
• 每次交易至少需要21000 gas,可否多个交易封在一个交易里

• 如何在同一个交易里同时调用合约里的多个(次)函数?


**举例：**

function multicall(bytes[] calldata data) external virtual returns (bytes[]
memory results) {
results = new bytes[](data.length);
for (uint256 i = 0; i < data.length; i++) {
results[i] = this.delegateCall(data[i]);
}
return results;
}

这个代码片段是一个用于在以太坊智能合约中实现多调用（multi-call）功能的函数。多调用功能允许在一个交易中调用多个函数，这在批量处理请求时可以提高效率并减少交易成本。


# MULTICALL - 读
• 打包读取和打包写入, 在一次 RPC 请求封装多个请求

• 降低网络请求

• 保证数据来自一个区块

• 打包写入,仅使用于不关注 msg.sender 情况。

## Viem 有原生集成: https://viem.sh/docs/contract/multicall.html
//通过 wagmi 创建的客户端实例，用于与以太坊区块链进行交互。
import { publicClient } from './client' 
//这是 wagmi 合约的 ABI（Application Binary Interface）定义，包含了合约的所有函数和事件的接口信息。
import { wagmiAbi } from './abi'

//定义常量，包含了合约的地址和 ABI。
const wagmiContract = {
  address: '0xFBA3912Ca04dd458c843e2EE08967fC04f3579c2',
  abi: wagmiAbi //合约得 ABI
} as const
 
//使用 publicClient.multicall 方法来同时异步调用多个合约函数。
//results: 这个变量将存储所有合约调用的结果。multicall 方法会并行地执行这些调用，并将结果按顺序存储在 results 数组中。
const results = await publicClient.multicall({
  contracts: [
  //使用扩展运算符 ... 复制 wagmiContract 对象的所有属性，并指定要调用的函数名为 totalSupply。
    {
      ...wagmiContract,
      functionName: 'totalSupply',
    },
    {
      ...wagmiContract,
      functionName: 'ownerOf',
      args: [69420n]
    },
    {
      ...wagmiContract,
      functionName: 'mint'
    }
  ]
})
/**
 * [
 *  { result: 424122n, status: 'success' },
 *  { result: '0xc961145a54C96E3aE9bAA048c4F4D6b04C13916b', status: 'success' },
 *  { error: [ContractFunctionExecutionError: ...], status: 'failure' }
 * ]
 */


