<template>
  <div class="transfer-records">
    <!-- 搜索区域 -->
    <div class="search-section">
      <el-row :gutter="20">
        <!-- 地址搜索卡片 -->
        <el-col :span="12">
          <el-card class="search-card">
            <template #header>
              <div class="card-header">
                <el-icon><Wallet /></el-icon>
                <span>按地址查询</span>
              </div>
            </template>
            <div class="search-content">
              <el-input
                v-model="searchAddress"
                placeholder="输入钱包地址查询转账记录"
                clearable
                @keyup.enter="searchByAddress"
                class="address-input"
              >
                <template #prefix>
                  <el-icon><Search /></el-icon>
                </template>
              </el-input>
              <el-button type="primary" @click="searchByAddress" :loading="loading">
                <el-icon><Search /></el-icon>
                查询
              </el-button>
            </div>
          </el-card>
        </el-col>

        <!-- 交易哈希搜索卡片 -->
        <el-col :span="12">
          <el-card class="search-card">
            <template #header>
              <div class="card-header">
                <el-icon><Document /></el-icon>
                <span>按交易哈希查询</span>
              </div>
            </template>
            <div class="search-content">
              <el-input
                v-model="searchHash"
                placeholder="输入交易哈希查询具体交易"
                clearable
                @keyup.enter="searchByHash"
                class="hash-input"
              >
                <template #prefix>
                  <el-icon><Search /></el-icon>
                </template>
              </el-input>
              <el-button type="primary" @click="searchByHash" :loading="loading">
                <el-icon><Search /></el-icon>
                查询
              </el-button>
            </div>
          </el-card>
        </el-col>
      </el-row>
    </div>

    <!-- 结果展示区域 -->
    <div class="results-section">
      <el-card class="results-card">
        <template #header>
          <div class="card-header">
            <div class="header-left">
              <el-icon><List /></el-icon>
              <span>查询结果</span>
            </div>
            <div class="header-right">
              <el-button v-if="transfers.length > 0" type="primary" link @click="fetchTransfers">
                <el-icon><Refresh /></el-icon>
                刷新
              </el-button>
            </div>
          </div>
        </template>

        <!-- 空状态 -->
        <el-empty
          v-if="transfers.length === 0"
          description="暂无转账记录"
        >
          <template #image>
            <el-icon :size="60"><Search /></el-icon>
          </template>
        </el-empty>

        <!-- 转账记录表格 -->
        <el-table
          v-else
          :data="transfers"
          style="width: 100%"
          v-loading="loading"
          stripe
          border
          highlight-current-row
        >
          <el-table-column label="发送地址" min-width="180" show-overflow-tooltip>
            <template #default="slotProps">
              <div class="address-container">
                <el-tag size="small" type="info" class="address-tag">
                  <el-icon><Wallet /></el-icon>
                  {{ formatAddress(slotProps?.row?.from_address || '') }}
                </el-tag>
                <el-button
                  size="small"
                  type="primary"
                  link
                  @click="copyToClipboard(slotProps?.row?.from_address)"
                >
                  <el-icon><CopyDocument /></el-icon>
                </el-button>
              </div>
            </template>
          </el-table-column>
          <el-table-column label="接收地址" min-width="180" show-overflow-tooltip>
            <template #default="slotProps">
              <div class="address-container">
                <el-tag size="small" type="success" class="address-tag">
                  <el-icon><Wallet /></el-icon>
                  {{ formatAddress(slotProps?.row?.to_address || '') }}
                </el-tag>
                <el-button
                  size="small"
                  type="primary"
                  link
                  @click="copyToClipboard(slotProps?.row?.to_address)"
                >
                  <el-icon><CopyDocument /></el-icon>
                </el-button>
              </div>
            </template>
          </el-table-column>
          <el-table-column label="金额" width="150" align="right">
            <template #default="slotProps">
              <span class="amount">{{ formatAmount(slotProps?.row?.amount || '0') }}</span>
              <span class="unit">ETH</span>
            </template>
          </el-table-column>
          <el-table-column label="交易哈希" min-width="220" show-overflow-tooltip>
            <template #default="slotProps">
              <el-link
                type="primary"
                :href="'https://sepolia.etherscan.io/tx/' + slotProps?.row?.transaction_hash"
                target="_blank"
                class="hash-link"
              >
                <el-icon><Link /></el-icon>
                {{ formatAddress(slotProps?.row?.transaction_hash || '') }}
              </el-link>
            </template>
          </el-table-column>
          <el-table-column label="时间" width="180">
            <template #default="slotProps">
              <el-tooltip
                :content="formatFullDate(slotProps?.row?.timestamp)"
                placement="top"
              >
                <span class="time">{{ formatDate(slotProps?.row?.timestamp) }}</span>
              </el-tooltip>
            </template>
          </el-table-column>
        </el-table>

        <!-- 分页 -->
        <div class="pagination" v-if="transfers.length > 0">
          <el-pagination
            :current-page="currentPage"
            :page-size="pageSize"
            :page-sizes="[10, 20, 50, 100]"
            layout="total, sizes, prev, pager, next"
            :total="total"
            @size-change="handleSizeChange"
            @current-change="handleCurrentChange"
          />
        </div>
      </el-card>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, defineExpose } from 'vue'
import axios from 'axios'
import { ElMessage } from 'element-plus'
import Web3 from 'web3'
import { Search, Document, Refresh, Link, List, Wallet, CopyDocument } from '@element-plus/icons-vue'

// 初始化web3实例
const web3 = new Web3(window.ethereum)

// 从环境变量获取API地址，如果未设置则使用默认值
const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:3000'

const transfers = ref([])
const loading = ref(false)
const currentPage = ref(1)
const pageSize = ref(10)
const total = ref(0)
const searchAddress = ref('')
const searchHash = ref('')

// 格式化地址显示
const formatAddress = (address) => {
  if (!address) return ''
  try {
    return `${address.slice(0, 6)}...${address.slice(-4)}`
  } catch (error) {
    console.error('地址格式化错误:', error)
    return address
  }
}

// 格式化金额显示（假设金额以wei为单位）
const formatAmount = (amount) => {
  if (!amount) return '0'
  try {
    return web3.utils.fromWei(amount, 'ether')
  } catch (error) {
    console.error('金额格式化错误:', error)
    return amount
  }
}

// 格式化日期显示（简短格式）
const formatDate = (timestamp) => {
  if (!timestamp) return ''
  try {
    const date = new Date(timestamp)
    return date.toLocaleString('zh-CN', {
      month: '2-digit',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit'
    })
  } catch (error) {
    console.error('日期格式化错误:', error)
    return timestamp
  }
}

// 格式化完整日期（用于tooltip）
const formatFullDate = (timestamp) => {
  if (!timestamp) return ''
  try {
    return new Date(timestamp).toLocaleString('zh-CN', {
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit'
    })
  } catch (error) {
    console.error('日期格式化错误:', error)
    return timestamp
  }
}

// 获取所有转账记录
const fetchTransfers = async () => {
  loading.value = true
  try {
    const response = await axios.get(`${API_BASE_URL}/transfer`, {
      params: {
        page: currentPage.value,
        limit: pageSize.value
      }
    })
    console.log('API响应数据:', response.data)
    if (Array.isArray(response.data.transfers)) {
      transfers.value = response.data.transfers
      total.value = response.data.total || 0
    } else {
      console.error('API返回的数据格式不正确:', response.data)
      transfers.value = []
      total.value = 0
      ElMessage.error('数据格式不正确')
    }
  } catch (error) {
    console.error('获取转账记录失败:', error)
    ElMessage.error('获取转账记录失败')
    transfers.value = []
    total.value = 0
  } finally {
    loading.value = false
  }
}

// 按地址搜索
const searchByAddress = async () => {
  if (!searchAddress.value) {
    ElMessage.warning('请输入钱包地址')
    return
  }
  loading.value = true
  try {
    // 将地址转换为大写
    const upperAddress = searchAddress.value.toUpperCase()
    const response = await axios.get(`${API_BASE_URL}/transfer/by-address`, {
      params: {
        address: upperAddress,
        page: currentPage.value,
        limit: pageSize.value
      }
    })
    if (Array.isArray(response.data.transfers)) {
      transfers.value = response.data.transfers
      total.value = response.data.total || 0
      if (transfers.value.length === 0) {
        ElMessage.info('未找到相关转账记录')
      }
    } else {
      transfers.value = []
      total.value = 0
      ElMessage.warning('未找到相关转账记录')
    }
  } catch (error) {
    console.error('查询地址记录失败:', error)
    ElMessage.error('查询地址记录失败')
    transfers.value = []
    total.value = 0
  } finally {
    loading.value = false
  }
}

// 按交易哈希搜索
const searchByHash = async () => {
  if (!searchHash.value) {
    ElMessage.warning('请输入交易哈希')
    return
  }
  loading.value = true
  try {
    const response = await axios.get(`${API_BASE_URL}/transfer/by-hash`, {
      params: {
        hash: searchHash.value
      }
    })
    if (response.data) {
      transfers.value = [response.data]
      total.value = 1
    } else {
      transfers.value = []
      total.value = 0
      ElMessage.warning('未找到相关交易记录')
    }
  } catch (error) {
    console.error('查询交易记录失败:', error)
    ElMessage.error('查询交易记录失败')
    transfers.value = []
    total.value = 0
  } finally {
    loading.value = false
  }
}

// 处理页码变化
const handleCurrentChange = (page) => {
  currentPage.value = page
  if (searchAddress.value) {
    searchByAddress()
  } else {
    fetchTransfers()
  }
}

// 处理每页条数变化
const handleSizeChange = (size) => {
  pageSize.value = size
  currentPage.value = 1
  if (searchAddress.value) {
    searchByAddress()
  } else {
    fetchTransfers()
  }
}

// 复制到剪贴板
const copyToClipboard = async (text) => {
  try {
    await navigator.clipboard.writeText(text)
    ElMessage.success('地址已复制到剪贴板')
  } catch (error) {
    console.error('复制失败:', error)
    ElMessage.error('复制失败')
  }
}

// 接收钱包地址并自动查询
const searchByConnectedWallet = async (walletAddress) => {
  if (!walletAddress) {
    ElMessage.warning('未获取到钱包地址')
    return
  }
  // 将地址转换为大写后再设置
  searchAddress.value = walletAddress.toUpperCase()
  await searchByAddress()
}

// 暴露方法给父组件
defineExpose({
  searchByConnectedWallet
})

// 组件挂载时获取数据
onMounted(() => {
  fetchTransfers()
})
</script>

<style scoped>
.transfer-records {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.search-section {
  margin-bottom: 20px;
}

.search-card {
  height: 100%;
  border-radius: 8px;
  transition: all 0.3s;
}

.search-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.1);
}

.card-header {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 16px;
  font-weight: 500;
}

.search-content {
  display: flex;
  gap: 12px;
  align-items: flex-start;
}

.search-content .el-input {
  flex: 1;
}

.address-input :deep(input),
.hash-input :deep(input) {
  font-family: monospace;
  font-size: 14px;
  padding: 8px 12px;
  height: 40px;
  width: 100%;
  min-width: 420px;
}

.results-card {
  border-radius: 8px;
}

.header-left {
  display: flex;
  align-items: center;
  gap: 8px;
}

.header-right {
  display: flex;
  align-items: center;
}

.address-container {
  display: flex;
  align-items: center;
  gap: 8px;
}

.address-tag {
  flex: 1;
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding: 4px 8px;
}

.amount {
  font-family: monospace;
  font-weight: 500;
  font-size: 14px;
}

.unit {
  margin-left: 4px;
  color: #909399;
  font-size: 12px;
}

.hash-link {
  display: inline-flex;
  align-items: center;
  gap: 4px;
}

.time {
  color: #606266;
  font-size: 13px;
}

.pagination {
  margin-top: 20px;
  display: flex;
  justify-content: flex-end;
}

@media (max-width: 768px) {
  .el-row {
    margin: 0 !important;
  }

  .el-col {
    padding: 0 !important;
  }

  .search-card {
    margin-bottom: 16px;
  }

  .search-content {
    flex-direction: column;
  }

  .search-content .el-input,
  .search-content .el-button {
    width: 100%;
  }

  .address-input :deep(input),
  .hash-input :deep(input) {
    min-width: unset;
  }

  .el-table {
    margin: 0 -20px;
    width: calc(100% + 40px);
  }
}
</style> 