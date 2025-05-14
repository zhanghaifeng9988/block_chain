<script setup>
import { ref, onMounted, computed } from 'vue'
import { createPublicClient, createWalletClient, custom, parseEther, formatEther } from 'viem'
import { localhost } from 'viem/chains'
import detectEthereumProvider from '@metamask/detect-provider'
import TokenBankABI from './contracts/TokenBank.json'
import TokenABI from './contracts/Token.json'

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
      functionName: 'getBalance',
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
  <div class="container">
    <h1>TokenBank DApp</h1>
    
    <div v-if="!isConnected" class="connect-section">
      <button @click="connectWallet" class="connect-btn">连接钱包</button>
    </div>

    <div v-else class="bank-section">
      <div class="info-section">
        <p>当前账户: {{ shortAddress }}</p>
        <p>Token 余额: {{ tokenBalance }} TOKEN</p>
        <p>Bank 存款: {{ bankBalance }} TOKEN</p>
      </div>

      <div class="action-section">
        <div class="input-group">
          <input 
            v-model="amount" 
            type="number" 
            placeholder="输入数量"
            :disabled="isLoading"
          >
          <div class="button-group">
            <button 
              @click="deposit" 
              :disabled="isLoading || !amount"
              class="action-btn deposit"
            >
              存款
            </button>
            <button 
              @click="withdraw" 
              :disabled="isLoading || !amount"
              class="action-btn withdraw"
            >
              取款
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.container {
  max-width: 800px;
  margin: 0 auto;
  padding: 2rem;
  text-align: center;
}

h1 {
  color: #2c3e50;
  margin-bottom: 2rem;
}

.connect-section {
  margin: 2rem 0;
}

.connect-btn {
  background-color: #4CAF50;
  color: white;
  padding: 1rem 2rem;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-size: 1.1rem;
}

.bank-section {
  background-color: #f8f9fa;
  padding: 2rem;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

.info-section {
  margin-bottom: 2rem;
}

.info-section p {
  margin: 0.5rem 0;
  font-size: 1.1rem;
  color: #2c3e50;
}

.input-group {
  display: flex;
  flex-direction: column;
  gap: 1rem;
  max-width: 400px;
  margin: 0 auto;
}

input {
  padding: 0.8rem;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 1rem;
}

.button-group {
  display: flex;
  gap: 1rem;
  justify-content: center;
}

.action-btn {
  padding: 0.8rem 1.5rem;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-size: 1rem;
  flex: 1;
  transition: opacity 0.3s;
}

.action-btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.deposit {
  background-color: #4CAF50;
  color: white;
}

.withdraw {
  background-color: #f44336;
  color: white;
}
</style>
