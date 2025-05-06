# 以太币单位
最小单位: Wei (伟)

• 10^9 Wei = 1 Gwei

• 10^12 Wei = 1 szabo (萨博)

• 10^15 Wei = 1 finey (芬尼)

• 10^18 Wei = 1 Ether

# 计算gas费
gas费计算公式：
gas费 = gasLimit * gasPrice

gasLimit：用户愿意支付最大数量
gasPrice：gas的单价，单位是Gwei
- gasPrice的确定：用户可以根据网络情况、交易量、交易类型等因素来确定。系统会推荐合理的gas单价，但用户可以根据自己的需求调整。越高的gas单价意味着交易的确认速度越快，但也意味着交易的成本越高。

## Priority Fee 计算（每 Gas 小费）
Priority Fee=min(MaxPriorityFeePerGas,MaxFeePerGas−Base Fee)


## **gasPrice**的计算（每 Gas 总费用）
MaxFeePerGas=Base Fee  +  Priority Fee
1. 根据区块使用率,系统动态调节基础费用 Base Fee；
2. 优先费,用户自行设置,作为矿工的奖励；
3. **基础费销毁**

## 燃烧掉的和矿工收益
燃烧掉 = Base Fee * gas used
矿工收益 = Priority Fee * gas used

0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2


# Gas 消耗量（Gas Used）
1. 定义：交易实际执行消耗的 Gas 数量，由以太坊虚拟机（EVM）计算得出。
2. Gas Used = 基础交易费（21,000） + 执行合约代码的 Gas
3. 如何获取：
- 通过区块链浏览器（如 Etherscan）查看交易的 Gas Used 字段。
- 使用 eth_estimateGas API 预估。

# 深入理解  Gas 费用 （你支付的 ETH 金额）
总费用（ETH） = Gas Used × Gas Price（单位：Gwei）
示例：总费用 = 50,000 × 20 Gwei = 1,000,000 Gwei = 0.001 ETH

# Gas Limit 的作用
1. 定义：你为交易设置的 Gas 预算上限（防止代码错误耗尽 Gas）。
2. 规则：
- 如果 Gas Used ≤ Gas Limit：交易成功，按实际消耗收费。
- 如果 Gas Used > Gas Limit：交易失败，但仍会扣除 Gas Limit × Gas Price 的 ETH。