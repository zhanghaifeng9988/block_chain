<script setup>
import { ref, onMounted, computed } from 'vue'
import { createPublicClient, createWalletClient, custom, parseEther, formatEther, recoverMessageAddress, getContract, parseSignature } from 'viem'
import { localhost } from 'viem/chains'
import detectEthereumProvider from '@metamask/detect-provider'
import TokenBankArtifact from './contracts/PermitTokenBank.json'
import TokenArtifact from './contracts/PermitToken.json'
import { useWallet } from 'vue-dapp'

// 自定义本地链配置
const anvilChain = {
  ...localhost,
  id: 31337,
  name: 'Anvil Local',
  network: 'anvil',
  nativeCurrency: {
    decimals: 18,
    name: 'Ether',
    symbol: 'ETH',
  },
  rpcUrls: {
    default: { http: ['http://127.0.0.1:8545'] },
    public: { http: ['http://127.0.0.1:8545'] },
  },
}

// ========== 合约地址 ==========
const tokenAddress = "0x5FbDB2315678afecb367f032d93F642f64180aa3";
const bankAddress = "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512";

// ========== 响应式状态 ==========
const isConnected = ref(false)
const account = ref('')
const tokenBalance = ref('0')
const bankBalance = ref('0')
const amount = ref('')
const isLoading = ref(false)

// ========== 计算属性 ==========
// 缩短地址显示（0x1234...5678）
const shortAddress = computed(() => {
  if (!account.value) return ''
  return `${account.value.slice(0, 6)}...${account.value.slice(-4)}`
})

// ========== Viem客户端 ==========
// 公共客户端（用于读取链上数据）
const publicClient = createPublicClient({
  chain: anvilChain,
  transport: custom(window.ethereum)
})

const TokenBankABI = TokenBankArtifact.abi
const TokenABI = TokenArtifact.abi

// ========== 主要函数 ==========

/**
 * 连接钱包函数
 */
const connectWallet = async () => {
  try {
    const provider = await detectEthereumProvider()
    if (!provider) {
      alert('请安装 MetaMask!')
      return
    }

    // 尝试切换到正确的链（Anvil本地链）
    try {
      await window.ethereum.request({
        method: 'wallet_switchEthereumChain',
        params: [{ chainId: '0x7A69' }], // 31337 的十六进制
      })
    } catch (switchError) {
      // 如果链不存在，添加它
      if (switchError.code === 4902) {
        await window.ethereum.request({
          method: 'wallet_addEthereumChain',
          params: [{
            chainId: '0x7A69',
            chainName: 'Anvil Local',
            nativeCurrency: {
              name: 'Ether',
              symbol: 'ETH',
              decimals: 18
            },
            rpcUrls: ['http://127.0.0.1:8545']
          }]
        })
      }
    }

    //读取钱包中，账户的信息
    // 请求账户访问权限  //eth_requestAccounts 这是前端连接钱包的请求方法，不含交易
    const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' })
    account.value = accounts[0]
    isConnected.value = true

    // 监听账户变化
    window.ethereum.on('accountsChanged', (accounts) => {
      account.value = accounts[0]
      updateBalances()// 账户变化时更新余额
    })

    // 初始更新余额
    await updateBalances()
  } catch (error) {
    console.error('连接钱包失败:', error)
  }
}

/**
 * 更新代币和银行余额
 */
const updateBalances = async () => {
  try {
    // 获取 Token 余额
    const tokenBalanceData = await publicClient.readContract({
      address: tokenAddress,
      abi: TokenABI,
      functionName: 'balanceOf',
      args: [account.value]
    })
    tokenBalance.value = formatEther(tokenBalanceData)

    // 获取 Bank 存款余额
    const bankBalanceData = await publicClient.readContract({
      address: bankAddress,
      abi: TokenBankABI,
      functionName: 'getDepositRecord',
      args: [account.value]
    })
    bankBalance.value = formatEther(bankBalanceData)
  } catch (error) {
    console.error('更新余额失败:', error)
  }
}

/**
 * 存款函数
 */
const deposit = async () => {
  if (!amount.value) return
  isLoading.value = true
  try {
    const depositAmount = parseEther(amount.value.toString())
    
    // 创建新的 walletClient
    const walletClient = createWalletClient({
      chain: anvilChain,
      transport: custom(window.ethereum),
      account: account.value
    })
    
    // 先授权 TokenBank 使用代币
    const approveHash = await walletClient.writeContract({
      address: tokenAddress,
      abi: TokenABI,
      functionName: 'approve',
      args: [bankAddress, depositAmount]
    })
    await publicClient.waitForTransactionReceipt({ hash: approveHash })

    // 存款到 TokenBank
    const hash = await walletClient.writeContract({
      address: bankAddress,
      abi: TokenBankABI,
      functionName: 'deposit',
      args: [depositAmount]
    })
    await publicClient.waitForTransactionReceipt({ hash })
    
    amount.value = ''
    await updateBalances()
  } catch (error) {
    console.error('存款失败:', error)
  } finally {
    isLoading.value = false
  }
}

const withdraw = async () => {
  if (!amount.value) return
  isLoading.value = true
  try {
    const withdrawAmount = parseEther(amount.value.toString())
    
    // 创建新的 walletClient
    const walletClient = createWalletClient({
      chain: anvilChain,
      transport: custom(window.ethereum),
      account: account.value
    })
    
    const hash = await walletClient.writeContract({
      address: bankAddress,
      abi: TokenBankABI,
      functionName: 'withdraw',
      args: [withdrawAmount]
    })
    await publicClient.waitForTransactionReceipt({ hash })
    
    amount.value = ''
    await updateBalances()
  } catch (error) {
    console.error('取款失败:', error)
  } finally {
    isLoading.value = false
  }
}

const permitDeposit = async () => {
  console.log('amount.value 原始值:', amount.value, typeof amount.value)
  if (!amount.value || isNaN(Number(amount.value))) {
    alert('请输入合法的存款金额')
    isLoading.value = false
    return
  }
  isLoading.value = true
  try {
    let depositAmount
    try {
      depositAmount = parseEther(amount.value.toString())
    } catch (e) {
      alert('存款金额格式错误: ' + amount.value)
      console.error('parseEther error:', e)
      isLoading.value = false
      return
    }
    const deadline = Math.floor(Date.now() / 1000) + 3600 // 1小时后过期

    // 检查钱包是否连接
    if (!account.value) {
      alert('请先连接钱包')
      isLoading.value = false
      return
    }

    let nonce
    try {
      nonce = await publicClient.readContract({
        address: tokenAddress,
        abi: TokenABI,
        functionName: 'nonces',
        args: [account.value]
      })
    } catch (e) {
      alert('获取 nonce 失败: ' + e)
      console.error('nonce error:', e)
      isLoading.value = false
      return
    }

    // 日志调试
    console.log('amount.value', amount.value)
    console.log('depositAmount', depositAmount)
    console.log('nonce', nonce)
    console.log('account.value', account.value)

    if (typeof depositAmount === 'undefined' || depositAmount === null) {
      alert('存款金额无效')
      isLoading.value = false
      return
    }
    if (typeof nonce === 'undefined' || nonce === null) {
      alert('获取 nonce 失败，请重试')
      isLoading.value = false
      return
    }

    // 获取链ID
    const chainId = anvilChain.id

    // 构造 EIP-2612 Permit 签名数据
    const domain = {
      name: 'ERC2612_study',
      version: '1',
      chainId,
      verifyingContract: tokenAddress
    }
    const types = {
      Permit: [
        { name: 'owner', type: 'address' },
        { name: 'spender', type: 'address' },
        { name: 'value', type: 'uint256' },
        { name: 'nonce', type: 'uint256' },
        { name: 'deadline', type: 'uint256' }
      ]
    }
    const values = {
      owner: account.value,
      spender: bankAddress,
      value: depositAmount,
      nonce: nonce,
      deadline: deadline
    }

    // 创建 walletClient 实例
    const walletClient = createWalletClient({
      chain: anvilChain,
      transport: custom(window.ethereum),
      account: account.value
    })

    // 使用 walletClient.signTypedData 进行签名
    const signatureHex = await walletClient.signTypedData({
      account: account.value,
      domain,
      types,
      primaryType: 'Permit',
      message: values
    })
    const { v, r, s } = parseSignature(signatureHex)
    console.log('signature', signatureHex)
    console.log('v', v, 'r', r, 's', s)

    // 调用 permitDeposit
    const hash = await walletClient.writeContract({
      address: bankAddress,
      abi: TokenBankABI,
      functionName: 'permitDeposit',
      args: [depositAmount, deadline, v, r, s]
    })
    await publicClient.waitForTransactionReceipt({ hash })
    amount.value = ''
    await updateBalances()
  } catch (error) {
    console.error('permit 存款失败:', error)
    alert('permit 存款失败: ' + error)
  } finally {
    isLoading.value = false
  }
}

// ========== 生命周期钩子 ==========
// 组件挂载时检查是否已连接钱包
onMounted(async () => {
  const provider = await detectEthereumProvider()
  if (provider) {
    const accounts = await window.ethereum.request({ method: 'eth_accounts' })
    if (accounts.length > 0) {
      account.value = accounts[0]
      isConnected.value = true
      await updateBalances()
    }
  }
})
</script>

<template>
  <div class="app">
    <el-container>
      <el-header>
        <h1>Token Bank</h1>
        <div class="wallet-section">
          <template v-if="!isConnected">
            <el-button type="primary" @click="connectWallet">连接钱包</el-button>
          </template>
          <template v-else>
            <el-button type="info" @click="disconnect">断开连接</el-button>
            <span class="address">{{ shortAddress }}</span>
          </template>
        </div>
      </el-header>
      
      <el-main>
        <div class="balance-section">
          <h2>我的余额</h2>
          <p>Token 余额: {{ tokenBalance }}</p>
          <p>Bank 余额: {{ bankBalance }}</p>
        </div>

        <div class="action-section">
          <el-card>
            <template #header>
              <div class="card-header">
                <span>存款</span>
              </div>
            </template>
            <el-input v-model="amount" placeholder="输入存款数量">
              <template #append>
                <el-button @click="deposit" :disabled="isLoading || !amount">存款</el-button>
              </template>
            </el-input>
          </el-card>

          <el-card>
            <template #header>
              <div class="card-header">
                <span>取款</span>
              </div>
            </template>
            <el-input v-model="amount" placeholder="输入取款数量">
              <template #append>
                <el-button @click="withdraw" :disabled="isLoading || !amount">取款</el-button>
              </template>
            </el-input>
          </el-card>
        </div>
      </el-main>
    </el-container>
  </div>
</template>

<style scoped>
.app {
  max-width: 1200px;
  margin: 0 auto;
  padding: 20px;
}

.el-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px;
  background-color: #f5f7fa;
}

.wallet-section {
  display: flex;
  align-items: center;
  gap: 10px;
}

.address {
  font-family: monospace;
  background-color: #eee;
  padding: 4px 8px;
  border-radius: 4px;
}

.balance-section {
  margin: 20px 0;
  padding: 20px;
  background-color: #f5f7fa;
  border-radius: 8px;
}

.action-section {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 20px;
  margin-top: 20px;
}

.el-card {
  margin-bottom: 20px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}
</style>
