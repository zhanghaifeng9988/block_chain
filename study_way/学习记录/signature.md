# 前置概念  
## RLP（Recursive Length Prefix，递归长度前缀）编码是以太坊中用于**序列化数据结构的核心编码方案**，专为区块链设计。

它的核心目标是以紧凑、无歧义的方式**将任意嵌套的数据结构转换为字节序列**，同时避免复杂的类型标记（如JSON/XML中的标签）。

**是原始数据结构的编码方案**，可以用于任何需要序列化的数据结构


## abi.encode 
abi.encode 是 Solidity 中用于 将函数参数或数据**按 ABI（应用二进制接口）标准**
**编码为字节序列** 的核心函数。


event Log(bytes data);
function emitLog(uint value) public {
    emit Log(abi.encode(value));
}

**上面的的代码**，表示：将 uint 类型的值 value 按照 ABI 编码为字节序列。



bytes memory data = abi.encodeWithSignature("transfer(address,uint256)", to, amount);
(bool success, ) = token.call(data);

**上面的代码**，表示：将函数名为 transfer 的参数（to 和 amount）按照 ABI 编码为字节序列。
call函数用于执行智能合约的交易，将字节序列作为参数。
data将是1个字节形式，包含：函数签名（4个字节）+ 32字节的 to 地址 + 32字节的 amount 值。


# 签名定义
1. 身份验证（Who）
- 去中心化登录（如 "Sign-In with Ethereum"）
- NFT 持有者验证
- 签名消息 "我同意条款" → 如果条款被篡改，签名验证失败。

2. 操作授权
- 交易执行
用户对交易数据签名，授权链上操作（如转账、合约调用）。

- 智能合约权限控制
合约可通过签名验证调用者权限（如多签钱包、DAO 投票）。

3. 数据完整性
结构化数据签名
使用标准（如 EIP-191/EIP-712）确保签名上下文明确，防止重放攻击。



# 签名性质
签名是无GAS费用的，是区块链上交易的基础。
签名是线下行为


# 详细解释
## 登录连接签名
属于：普通消息签名；
前端连接本地钱包，返回用户地址
这种行为，代码实现：const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' })


## 利用EIP191
EIP191协议中得encoding Spec✅ **"增加0x19前缀**，表示这**是结构化签名数据**（可能是消息或安全交易编码），
而不仅是原始交易数据；

核心区别
| 场景 | 数据格式示例 | 用途 | 
|------|-----------|-------| 
| 普通消息签名 | 0x19 + 0x45（以太坊标准消息前缀） | 登录/验证身份 | 
| 安全交易编码 | 0x19 + 0x01（合约自定义交易前缀） | 多签交易等 |

## EIP191解释
![1747219862369](image/signature/1747219862369.png)
EIP191: 区分交易签名和其他信息签名

• 0x19 初始字节: 这个初始字节确保 signed_data **不是 RLP 编码**,从而防止签名数据被误解为以太坊交易。

• <1 byte version>:可以自行定义签名数据版本,占用一字节,可以是0;

• <version sepific data>: 不定长的消息头数据;

• <data to sign>:原始签名数据;


## 原始交易数据（Raw Transaction Data）
在区块链中，原始交易数据（Raw Transaction Data） 指的是未经结构化处理、直接用于链上执行的交易二进制数据。
**格式：通常为RLP**（Recursive Length Prefix）编码的字节序列。

示例结构：
{
  nonce: 0x1,
  gasPrice: 0x09184e72a000,
  gasLimit: 0x21000,
  to: "0x接收地址",
  value: 0x1,
  data: "0x...", // 调用合约时的输入数据
  chainId: 1     // 主网ID
}

### 安全风险：

原始交易数据若被直接签名，可能被恶意重放（如重复转账）。
EIP-191的0x19前缀强制结构化数据，防止此类攻击（如添加chainId和合约地址约束）。


## 典型场景
原始交易：普通ETH转账、简单的合约调用。
结构化数据：多签交易（Gnosis Safe）、登录签名（SIWE）、EIP-712复杂数据签名。

## 总结
原始交易数据：裸交易二进制，直接签名存在风险。
结构化数据（含0x19）：通过版本标识和域分隔符保障安全，明确签名用途。


# 区块链上发生交易，用户、前端与钱包的工作流程与签名机制
```mermaid
sequenceDiagram
    actor 用户
    participant 前端 as 前端 DApp
    participant 钱包 as 用户钱包
    participant 区块链 as 区块链节点

    # 用户输入环节
    用户->>前端: 1. 填写交易数据
    Note left of 用户: 输入内容：\n▪ 接收地址\n▪ 转账金额\n▪ Gas参数（可选）
    前端->>前端: 2. 校验数据格式

    # 交易构造与序列化
    前端->>前端: 3. 构造原始交易对象
    Note left of 前端: rawTx = {<br/>  nonce: 0x1,<br/>  to: '0x...',<br/>  value: '0x...',<br/>  gasPrice: '0x...',<br/>  gasLimit: '0x...'<br/>}
    前端->>前端: 4. RLP序列化
    Note left of 前端: serializedTx = RLP.encode(rawTx)
    前端->>前端: 5. 生成交易哈希
    Note left of 前端: hash = keccak256(serializedTx)

    # 钱包连接与签名
    前端->>钱包: 6. 连接钱包(eth_requestAccounts)
    钱包-->>前端: 返回账户地址
    
    前端->>钱包: 7. 签名请求(发送hash)
    Note right of 钱包: 请求类型：\n▪ personal_sign\n▪ eth_signTypedData_v4
    钱包->>用户: 弹出确认窗口
    用户->>钱包: 点击授权
    
    钱包->>钱包: 8. ECDSA签名
    Note left of 钱包: 生成签名参数\n(v, r, s)
    
    钱包-->>前端: 9. 返回签名结果
    alt 交易签名
        前端->>前端: 10. 组合签名交易
        Note left of 前端: signedTx = serializedTx + signature
        前端->>区块链: 11. 广播signedTx
        区块链->>区块链: 12. 验证签名及交易
        Note left of 区块链: 校验内容：\n▪ RLP解码signedTx\n▪ 验证hash和签名
        区块链-->>前端: 13. 返回交易哈希
    else 消息签名
        前端->>前端: 10. 验证hash与签名匹配
    end
```



# 去中心化得用户身份认证（后端）
SIWE（Sign-In with Ethereum，EIP-4361） 是一种基于以太坊的去中心化身份认证机制，用于实现无信任的登录、权限验证和身份认证。
 ## 用户控制私钥
钱包管理私钥：用户的私钥完全存储在用户的设备（钱包）上，比如 MetaMask、WalletConnect 或其他钱包应用。
无需信任第三方：用户不需要将私钥交给任何中心化服务。用户的地址相关操作（如签名）只在钱包中完成，验证逻辑由后端执行。


```mermaid
sequenceDiagram
    actor 用户
    participant 前端 as 用户前端 DApp
    participant 钱包 as 用户钱包
    participant 后端 as 服务后端
    participant 区块链 as 以太坊区块链

    用户->>前端: 填写登录信息
    前端->>后端: 请求登录
    后端-->>前端: 返回 nonce 和消息模板
    前端->>钱包: 请求用户签署消息
    钱包->>用户: 弹出签名确认
    用户->>钱包: 确认签名
    钱包-->>前端: 返回签名结果

    note right of 钱包:: 签名过程：使用私钥对消息哈希签名（使用以太坊的 ECDSA 算法）。签名结果 (v, r, s) 返回给前端。

    前端->>后端: 提交签名数据 (message, signature)

    note right of 后端:: 后端执行以下验证过程：签名合法性：通过 blockchain 确认签名是否与地址匹配。消息完整性：验证消息哈希是否被篡改。nonce 唯一性：检查 nonce 是否已被使用。链 ID 合法性：确保指定的 chainId 与区块链环境匹配。

    后端->>后端: 验证签名及消息

    alt 验证通过
        后端->>区块链: 查询链上数据（验证地址规则）（不直接交互，但验证基于区块链规则）
        后端-->>前端: 发放 JWT Token
        前端->>用户: 显示登录成功
    else 验证失败
        后端-->>前端: 错误响应
        前端->>用户: 提示用户重新登录
    end

    note over 区块链:: 区块链的作用：定义了签名算法 (ECDSA) 和地址生成规则。后端的验证过程依赖区块链的规则，但无需直接交互。
```

## 总结
就是用户登录信息进行私钥签名，然后后端验证签名，然后返回 JWT Token 给前端，前端根据 Token 进行身份验证。
后端验证是通过区块链查询链上数据，但无需直接交互。


# EIP-712（以太坊类型化数据签名标准）
是以太坊上用于结构化数据签名的协议，旨在提升用户签名时的透明度和安全性。以下是简明介绍：

| 特性 | 说明 | 
|---------------------|------------| 
| 结构化数据 | 支持嵌套数据类型（如Person{name, wallet}），类似JSON但可验证 | | 域名分隔符 | 绑定特定DApp和链，防止跨平台签名攻击 | | 前端友好 | 开发者可自定义显示字段（如将value: 100显示为"支付100 USDT"） |

## 代码示例：

// 1. 定义数据结构

![1747221200544](image/signature/1747221200544.png)

// 2. 请求签名（MetaMask会显示清晰字段）
const signature = await wallet.signTypedData(typedData);

// 3.签名展示
![1747221350745](image/signature/1747221350745.png)

## 对191得数据解构进行拓展
示例：
![1747222041619](image/signature/1747222041619.png)

# 签名得步骤
![1747218661039](image/signature/1747218661039.png)


