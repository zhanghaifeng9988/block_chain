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

## gasPrice的组成
分为两部分:基础费(base fee)和优先费(小费:tips fee)
1. 根据区块使用率,系统动态调节基础费用 base fee；
2. 优先费,用户自行设置,作为矿工的奖励；
3. **基础费销毁**

## 燃烧掉的和矿工收益
燃烧掉 = base fee * gas used
矿工收益 = tips fee * gas used

