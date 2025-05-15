<template>
  <div class="wallet-connect">
    <el-button
      v-if="!isConnected"
      type="primary"
      @click="showAccountSelector"
      :loading="connecting"
    >
      <el-icon><Wallet /></el-icon>
      连接钱包
    </el-button>
    <el-button
      v-else
      type="info"
      @click="disconnectWallet"
    >
      <el-icon><Wallet /></el-icon>
      {{ shortAddress }}
    </el-button>

    <!-- 账户选择对话框 -->
    <el-dialog
      v-model="dialogVisible"
      title="选择钱包账户"
      width="400px"
      :close-on-click-modal="false"
      :close-on-press-escape="false"
    >
      <div v-if="accounts.length > 0" class="accounts-list">
        <el-radio-group v-model="selectedAccount" class="account-radio-group">
          <el-radio
            v-for="acc in accounts"
            :key="acc"
            :label="acc"
            class="account-radio"
          >
            <div class="account-info">
              <el-icon><Wallet /></el-icon>
              <span class="address">{{ formatAddress(acc) }}</span>
            </div>
          </el-radio>
        </el-radio-group>
      </div>
      <div v-else class="no-accounts">
        <el-empty description="未检测到钱包账户" />
      </div>
      <template #footer>
        <span class="dialog-footer">
          <el-button @click="dialogVisible = false">取消</el-button>
          <el-button
            type="primary"
            @click="connectSelectedAccount"
            :disabled="!selectedAccount"
          >
            确认连接
          </el-button>
        </span>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { ElMessage } from 'element-plus'
import { Wallet } from '@element-plus/icons-vue'

const emit = defineEmits(['wallet-connected'])
const isConnected = ref(false)
const connecting = ref(false)
const account = ref('')
const dialogVisible = ref(false)
const accounts = ref([])
const selectedAccount = ref('')

// 格式化地址显示
const shortAddress = computed(() => {
  if (!account.value) return ''
  return formatAddress(account.value)
})

// 格式化地址
const formatAddress = (address) => {
  if (!address) return ''
  return `${address.slice(0, 6)}...${address.slice(-4)}`
}

// 显示账户选择器
const showAccountSelector = async () => {
  if (!window.ethereum) {
    ElMessage.error('请安装MetaMask钱包')
    return
  }

  connecting.value = true
  try {
    // 先检查是否已经有权限
    const permissions = await window.ethereum.request({
      method: 'wallet_getPermissions'
    })

    // 如果已经有权限，则撤销现有权限
    if (permissions.length > 0) {
      await window.ethereum.request({
        method: 'wallet_revokePermissions',
        params: [{
          eth_accounts: {}
        }]
      })
    }

    // 获取所有账户
    const allAccounts = await window.ethereum.request({
      method: 'eth_accounts'
    })

    if (allAccounts.length === 0) {
      // 如果没有账户，请求用户解锁钱包
      await window.ethereum.request({
        method: 'eth_requestAccounts'
      })
      
      // 再次获取账户
      const newAccounts = await window.ethereum.request({
        method: 'eth_accounts'
      })
      
      if (newAccounts.length === 0) {
        ElMessage.warning('请先解锁MetaMask钱包并添加账户')
        return
      }
      
      accounts.value = newAccounts
    } else {
      accounts.value = allAccounts
    }

    selectedAccount.value = accounts.value[0]
    dialogVisible.value = true
  } catch (error) {
    console.error('获取钱包账户失败:', error)
    ElMessage.error('获取钱包账户失败')
  } finally {
    connecting.value = false
  }
}

// 连接选中的账户
const connectSelectedAccount = async () => {
  if (!selectedAccount.value) {
    ElMessage.warning('请选择要连接的账户')
    return
  }

  try {
    // 请求特定账户的权限
    await window.ethereum.request({
      method: 'wallet_requestPermissions',
      params: [{
        eth_accounts: {}
      }]
    })

    // 获取当前连接的账户
    const connectedAccounts = await window.ethereum.request({
      method: 'eth_accounts'
    })

    // 如果获取到的账户不是用户选择的账户，则提示切换
    if (!connectedAccounts.includes(selectedAccount.value)) {
      ElMessage.info('请在MetaMask中切换到选择的账户')
      return
    }

    account.value = selectedAccount.value
    isConnected.value = true
    dialogVisible.value = false
    ElMessage.success('钱包连接成功')
    
    // 发送连接成功事件
    emit('wallet-connected', account.value)

    // 监听账户变化
    window.ethereum.on('accountsChanged', handleAccountsChanged)
  } catch (error) {
    console.error('连接账户失败:', error)
    ElMessage.error('连接账户失败')
  }
}

// 处理账户变化
const handleAccountsChanged = async (newAccounts) => {
  if (newAccounts.length === 0) {
    // 用户断开了钱包连接
    disconnectWallet()
  } else {
    // 更新当前账户
    account.value = newAccounts[0]
    emit('wallet-connected', account.value)
  }
}

// 断开钱包连接
const disconnectWallet = async () => {
  try {
    // 撤销权限
    await window.ethereum.request({
      method: 'wallet_revokePermissions',
      params: [{
        eth_accounts: {}
      }]
    })
  } catch (error) {
    console.error('撤销权限失败:', error)
  }

  account.value = ''
  selectedAccount.value = ''
  isConnected.value = false
  ElMessage.success('已断开钱包连接')
  
  // 移除账户变化监听
  window.ethereum?.removeListener('accountsChanged', handleAccountsChanged)
}
</script>

<style scoped>
.wallet-connect {
  display: flex;
  align-items: center;
}

.wallet-connect .el-button {
  display: inline-flex;
  align-items: center;
  gap: 8px;
}

.accounts-list {
  padding: 10px 0;
}

.account-radio-group {
  display: flex;
  flex-direction: column;
  gap: 12px;
  width: 100%;
}

.account-radio {
  margin-right: 0;
  padding: 12px;
  border-radius: 8px;
  transition: all 0.3s;
}

.account-radio:hover {
  background-color: var(--el-fill-color-light);
}

.account-info {
  display: flex;
  align-items: center;
  gap: 8px;
}

.address {
  font-family: monospace;
  font-size: 14px;
}

.no-accounts {
  padding: 20px 0;
}

.dialog-footer {
  display: flex;
  justify-content: flex-end;
  gap: 12px;
}

@media (max-width: 768px) {
  .wallet-connect .el-button {
    width: 100%;
    justify-content: center;
  }
}
</style> 