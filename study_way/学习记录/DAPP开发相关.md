# vue 的区块链生态

## viem 库
viem 是一个通用的以太坊交互库，**前后端**都可以使用；
1. 基础功能：
读取区块链数据
发送交易
与智能合约交互
处理钱包连接

2. 优势：
性能优秀
类型安全
模块化设计
支持多链
可以前后端通用
与 TypeScript 完美集成


## 前端库
1. vue-dapp
最流行的 Vue 区块链库之一
类似 wagmi 的功能，但专为 Vue 设计
提供 Vue 3 组合式 API 支持

2. vue-ethereum
另一个流行的 Vue 区块链库
提供更多底层功能!
## 选择建议：
如果你使用 Vue 3，推荐使用 vue-dapp
如果需要更多底层控制，可以考虑 vue-ethereum
两者都可以与 viem 配合使用


# AppKit!
AppKit 是一个基于 Node.js 的 SDK，但它不仅限于 Node.js 环境。让我详细解释：
环境支持：
Node.js 环境
浏览器环境
前端框架（React、Vue 等）
AppKit 是一个用于构建 Web3 应用程序的开发工具包：

1. 主要功能：
提供 Web3 应用开发的基础设施
简化区块链交互
提供预构建的组件和工具
支持多链开发

// 基本使用示例
   import { AppKit } from '@web3-appkit/core'
   
   // 初始化
   const appKit = new AppKit({
     // 配置选项
     chains: [
       {
         id: 1,
         name: 'Ethereum',
         rpcUrl: 'https://mainnet.infura.io/v3/...'
       }
     ],
     // 其他配置...
   })

2. 主要特点：
模块化设计
支持多链
提供 UI 组件
内置状态管理
支持插件系统


3. 常见使用场景：
 // 1. 钱包连接
   const { connect, disconnect, account } = appKit.wallet
   
   // 2. 合约交互
   const { contract } = appKit.contracts
   
   // 3. 交易处理
   const { sendTransaction } = appKit.transactions
   
   // 4. 事件监听
   const { subscribe } = appKit.events

4. 与其他库的关系：
可以与其他 Web3 库（如 viem、ethers.js）配合使用
提供更高层次的抽象
简化开发流程

5. 优势：
开发效率高
代码复用性好
维护成本低
社区支持

6. 使用建议：
适合快速开发 Web3 应用
适合需要多链支持的项目
适合需要预构建组件的项目


