# uniswap学习记录

## 介绍

Uniswap 是一款去中心化的自动做市商（AMM）协议，它允许用户通过代币交换来进行资产交易。Uniswap 由四个主要合约组成：


1. 核心合约架构：
   
   - UniswapV2ERC20 ：LP 代币合约，实现 ERC20 标准和 permit 功能
   - UniswapV2Factory ：工厂合约，负责创建和管理交易对
   - UniswapV2Pair ：交易对合约，实现核心的交换逻辑和价格预言机
   - UniswapV2Router02 ：路由合约，处理所有用户交互操作
2. 辅助库合约：
   
   - Math ：提供安全的数学计算函数
   - UQ112x112 ：处理定点数运算，用于价格计算
   - TransferHelper ：提供安全的代币转账方法
   - UniswapV2Library ：提供通用的计算和辅助函数
3. 关键实现要点：
   
   - 恒定乘积公式：x * y = k
   - 价格预言机：使用时间加权平均价格（TWAP）
   - 闪电贷：在一个交易中完成借贷和还款
   - 手续费：0.3% 的交易手续费
   - 最小流动性：防止第一个 LP 操纵价格
   - 安全转账：使用 TransferHelper 处理不规范的代币
4. 重要功能：
   
   - 添加/移除流动性（支持 ETH 和 ERC20）
   - 代币交换（精确输入/输出，支持 ETH）
   - 多跳路径交换
   - 价格查询和计算
   - 签名许可（permit）
5. 安全特性：
   
   - 重入锁
   - 溢出保护
   - 最小流动性锁定
   - 价格操纵防护
   - 交易截止时间
这些合约共同构建了一个去中心化、安全、高效的自动做市商（AMM）系统。每个合约都有其特定的职责，通过清晰的接口互相协作。

您是否对某个具体部分感兴趣？我可以为您详细解释任何感兴趣的模块。


## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
