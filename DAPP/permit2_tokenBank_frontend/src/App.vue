<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { useMetaMask } from './composables/useMetaMask'
import { useTokenBank } from './composables/useTokenBank'

const { address, isConnected, connect, disconnect, checkConnection } = useMetaMask()
const { tokenBalance, bankBalance, isLoading, getTokenBalance, getBankBalance, deposit, withdraw, permitDeposit, permit2Approve, depositWithPermit2 } = useTokenBank(address)

const depositAmount = ref('')
const withdrawAmount = ref('')

const shortAddress = computed(() => {
  if (!address.value) return ''
  return `${address.value.slice(0, 6)}...${address.value.slice(-4)}`
})

const handleDeposit = async () => {
  if (!depositAmount.value) return
  await deposit(depositAmount.value)
  depositAmount.value = ''
}

const handlePermitDeposit = async () => {
  if (!depositAmount.value) return
  await permitDeposit(depositAmount.value)
  depositAmount.value = ''
}

const handlePermit2Approve = async () => {
  if (!depositAmount.value) return
  await permit2Approve(depositAmount.value)
}

const handlePermit2Deposit = async () => {
  if (!depositAmount.value) return
  await depositWithPermit2(depositAmount.value)
}

const handleWithdraw = async () => {
  if (!withdrawAmount.value) return
  await withdraw(withdrawAmount.value)
  withdrawAmount.value = ''
}

onMounted(async () => {
  await checkConnection()
  if (address.value) {
    await Promise.all([getTokenBalance(), getBankBalance()])
  }
})

watch(address, async (val) => {
  if (val) {
    await Promise.all([getTokenBalance(), getBankBalance()])
  } else {
    // 地址断开时清零
    tokenBalance.value = '0'
    bankBalance.value = '0'
  }
})
</script>

<template>
  <div class="app-container">
    <div class="content-wrapper">
      <!-- 头部 -->
      <div class="header-card">
        <div class="header-content">
          <div class="header-flex">
            <h1 class="title">Token Bank</h1>
            <div class="wallet-section">
              <template v-if="!isConnected">
                <button
                  @click="connect"
                  class="connect-button"
                >
                  连接钱包
                </button>
              </template>
              <template v-else>
                <span class="address">{{ shortAddress }}</span>
                <button
                  @click="disconnect"
                  class="disconnect-button"
                >
                  断开连接
                </button>
              </template>
            </div>
          </div>
        </div>
      </div>

      <!-- 余额信息 -->
      <div class="balance-card">
        <div class="card-content">
          <h2 class="card-title">我的余额</h2>
          <div class="balance-grid">
            <div class="balance-item">
              <p class="balance-label">Token 余额</p>
              <p class="balance-value">{{ tokenBalance }}</p>
            </div>
            <div class="balance-item">
              <p class="balance-label">Bank 余额</p>
              <p class="balance-value">{{ bankBalance }}</p>
            </div>
          </div>
        </div>
      </div>

      <!-- 操作区域 -->
      <div class="operation-grid">
        <!-- 存款 -->
        <div class="operation-card">
          <div class="card-content">
            <h3 class="card-title">存款</h3>
            <div class="form-group">
              <div class="input-group">
                <label for="deposit-amount" class="input-label">金额</label>
                <input
                  type="number"
                  id="deposit-amount"
                  v-model="depositAmount"
                  class="input-field"
                  placeholder="输入存款金额"
                />
              </div>
              <div class="button-group">
                <button
                  @click="handleDeposit"
                  :disabled="isLoading || !depositAmount"
                  class="deposit-button"
                >
                  普通存款
                </button>
                <button
                  @click="handlePermitDeposit"
                  :disabled="isLoading || !depositAmount"
                  class="permit-button"
                >
                  Permit 存款
                </button>
                <button
                  @click="handlePermit2Approve"
                  :disabled="isLoading || !depositAmount"
                  class="permit-button"
                  style="background:#6366f1;"
                >
                  Permit2 授权
                </button>
                <button
                  @click="handlePermit2Deposit"
                  :disabled="isLoading || !depositAmount"
                  class="permit-button"
                  style="background:#22d3ee;"
                >
                  Permit2 存款
                </button>
              </div>
            </div>
          </div>
        </div>

        <!-- 取款 -->
        <div class="operation-card">
          <div class="card-content">
            <h3 class="card-title">取款</h3>
            <div class="form-group">
              <div class="input-group">
                <label for="withdraw-amount" class="input-label">金额</label>
                <input
                  type="number"
                  id="withdraw-amount"
                  v-model="withdrawAmount"
                  class="input-field"
                  placeholder="输入取款金额"
                />
              </div>
              <button
                @click="handleWithdraw"
                :disabled="isLoading || !withdrawAmount"
                class="withdraw-button"
              >
                取款
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.app-container {
  min-height: 100vh;
  background-color: #f3f4f6;
}

.content-wrapper {
  max-width: 1200px;
  margin: 0 auto;
  padding: 1.5rem;
}

.header-card,
.balance-card,
.operation-card {
  background-color: white;
  border-radius: 0.5rem;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
  margin-bottom: 1.5rem;
}

.header-content,
.card-content {
  padding: 1.5rem;
}

.header-flex {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.title {
  font-size: 1.5rem;
  font-weight: bold;
  color: #111827;
}

.wallet-section {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.address {
  font-size: 0.875rem;
  color: #6b7280;
}

.connect-button,
.disconnect-button,
.deposit-button,
.permit-button,
.withdraw-button {
  padding: 0.5rem 1rem;
  border-radius: 0.375rem;
  font-size: 0.875rem;
  font-weight: 500;
  cursor: pointer;
  border: none;
  transition: background-color 0.2s;
}

.connect-button,
.deposit-button {
  background-color: #4f46e5;
  color: white;
}

.connect-button:hover,
.deposit-button:hover {
  background-color: #4338ca;
}

.disconnect-button {
  background-color: #e0e7ff;
  color: #4f46e5;
}

.disconnect-button:hover {
  background-color: #c7d2fe;
}

.permit-button {
  background-color: #059669;
  color: white;
}

.permit-button:hover {
  background-color: #047857;
}

.withdraw-button {
  background-color: #dc2626;
  color: white;
}

.withdraw-button:hover {
  background-color: #b91c1c;
}

.balance-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 1rem;
  margin-top: 1rem;
}

.balance-item {
  background-color: #f9fafb;
  padding: 1rem;
  border-radius: 0.375rem;
}

.balance-label {
  font-size: 0.875rem;
  color: #6b7280;
  margin-bottom: 0.5rem;
}

.balance-value {
  font-size: 1.5rem;
  font-weight: 600;
  color: #111827;
}

.operation-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 1.5rem;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.input-group {
    display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.input-label {
  font-size: 0.875rem;
  font-weight: 500;
  color: #374151;
}

.input-field {
  padding: 0.5rem;
  border: 1px solid #d1d5db;
  border-radius: 0.375rem;
  font-size: 0.875rem;
  }

.input-field:focus {
  outline: none;
  border-color: #4f46e5;
  box-shadow: 0 0 0 2px rgba(79, 70, 229, 0.1);
  }

.button-group {
    display: flex;
  gap: 1rem;
  }

button:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}
</style>
