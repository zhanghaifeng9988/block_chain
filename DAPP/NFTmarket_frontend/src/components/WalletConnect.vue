<template>
  <div class="wallet-connect">
    <div v-if="!isConnected" class="connect-button">
      <button @click="connectWallet">连接钱包</button>
    </div>
    <div v-else class="wallet-info">
      <p>钱包地址: {{ truncatedAddress }}</p>
      <button @click="disconnectWallet">断开连接</button>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { createPublicClient, http, createWalletClient } from 'viem'
import { sepolia } from 'viem/chains'

const isConnected = ref(false)
const address = ref('')

const truncatedAddress = computed(() => {
  if (!address.value) return ''
  return `${address.value.slice(0, 6)}...${address.value.slice(-4)}`
})

const publicClient = createPublicClient({
  chain: sepolia,
  transport: http()
})

async function connectWallet() {
  try {
    if (!window.ethereum) {
      alert('请安装 MetaMask!')
      return
    }

    const accounts = await window.ethereum.request({
      method: 'eth_requestAccounts'
    })

    if (accounts.length > 0) {
      address.value = accounts[0]
      isConnected.value = true
      console.log('钱包连接成功:', address.value)
    }

    // 监听账户变化
    window.ethereum.on('accountsChanged', handleAccountsChanged)
  } catch (error) {
    console.error('连接钱包失败:', error)
  }
}

function handleAccountsChanged(accounts) {
  if (accounts.length === 0) {
    isConnected.value = false
    address.value = ''
  } else {
    address.value = accounts[0]
    isConnected.value = true
  }
}

function disconnectWallet() {
  isConnected.value = false
  address.value = ''
}

onMounted(async () => {
  // 检查是否已经连接
  if (window.ethereum) {
    const accounts = await window.ethereum.request({
      method: 'eth_accounts'
    })
    if (accounts.length > 0) {
      address.value = accounts[0]
      isConnected.value = true
    }
  }
})
</script>

<style scoped>
.wallet-connect {
  padding: 1rem;
  text-align: center;
}

button {
  background-color: #4CAF50;
  color: white;
  padding: 10px 20px;
  border: none;
  border-radius: 5px;
  cursor: pointer;
  font-size: 16px;
}

button:hover {
  background-color: #45a049;
}

.wallet-info {
  margin-top: 1rem;
}

.connect-button {
  margin: 1rem 0;
}
</style> 