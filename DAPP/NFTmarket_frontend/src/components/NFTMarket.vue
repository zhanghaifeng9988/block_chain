<template>
  <div class="nft-market">
    <div style="color:#888;font-size:14px;margin-bottom:8px;">仅显示最近2000区块的上架NFT，历史更久的请联系管理员。</div>
    <div v-if="error" class="error-message">
      {{ error }}
    </div>
    
    <div v-if="loading" class="loading">
      加载中...
    </div>

    <div v-else-if="!isConnected" class="connect-prompt">
      请先连接钱包以查看 NFT 市场
    </div>

    <div v-else class="market-container">
      <!-- 上架 NFT 按钮和表单 -->
      <div class="market-header">
        <h2>NFT 市场</h2>
        <button @click="showListForm = true" class="list-btn" v-if="!showListForm">
          上架新的 NFT
        </button>
      </div>

      <!-- 上架表单 -->
      <div v-if="showListForm" class="list-form-container">
        <div class="list-form">
          <div class="form-header">
            <h3>上架 NFT</h3>
            <button @click="showListForm = false" class="close-btn">&times;</button>
          </div>
          <div class="form-group">
            <label>NFT ID</label>
            <input type="number" v-model="listForm.tokenId" placeholder="输入 NFT ID">
          </div>
          <div class="form-group">
            <label>价格 (ERC20 Token)</label>
            <input type="number" v-model="listForm.price" placeholder="输入价格" step="0.01">
            <div style="color:#888;font-size:12px;margin-top:4px;">单位：ERC20 Token（如MTK、USDT等，实际为合约指定Token）</div>
          </div>
          <div class="form-buttons">
            <button @click="handleList" class="submit-btn" :disabled="isListing">
              {{ isListing ? '上架中...' : '确认上架' }}
            </button>
            <button @click="showListForm = false" class="cancel-btn">
              取消
            </button>
          </div>
        </div>
      </div>

      <!-- NFT 列表 -->
      <div class="nft-grid">
        <div v-if="nfts.length === 0 && !loading" style="grid-column: 1/-1;text-align:center;color:#888;">
          暂无上架NFT
        </div>
        <div v-for="nft in nfts" :key="nft.id" class="nft-card">
          <div class="nft-image-container">
            <img :src="nft.image" :alt="nft.name" class="nft-image">
          </div>
          <div class="nft-info">
            <h3>{{ nft.name }}</h3>
            <p class="price">{{ nft.price }} ETH</p>
            <p class="seller">卖家: {{ formatAddress(nft.seller) }}</p>
            <p style="color:#c00;font-size:12px;">[调试] seller: {{ nft.seller }}<br/>wallet: {{ walletAddress }}</p>
            <button
              v-if="nft.seller.toLowerCase() !== walletAddress?.toLowerCase()"
              @click="buyNFT(nft.id)"
              class="buy-btn"
              :disabled="isBuying"
            >
              {{ isBuying ? '购买中...' : '购买' }}
            </button>
            <button
              v-else
              class="buy-btn"
              disabled
              style="background:#ccc;cursor:not-allowed;"
            >
              不能购买自己上架的NFT
            </button>
            <button
              v-if="nft.seller && nft.seller.toLowerCase() === walletAddress?.toLowerCase()"
              @click="removeNFT(nft.id)"
              class="remove-btn"
              :disabled="isRemoving"
            >
              {{ isRemoving ? '下架中...' : '下架' }}
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, watch } from 'vue'
import { useWallet } from 'vue-dapp'
import { formatEther, parseEther } from 'viem'
import { CONTRACT_ADDRESSES, NFTMarketABI, NFTABI, publicClient, getWalletClient } from '../utils/contracts'
import { ERC20ABI } from '../contracts/abi'
import { ethers } from 'ethers'

const wallet = useWallet()
const nfts = ref([])
const loading = ref(false)
const error = ref(null)
const isBuying = ref(false)
const isListing = ref(false)
const isRemoving = ref(false)
const isConnected = ref(false)
const showListForm = ref(false)
const listForm = ref({
  tokenId: '',
  price: ''
})
const walletAddress = ref('')
let hasLoadedHistory = false

const formatAddress = (addr) => {
  if (!addr) return ''
  return `${addr.slice(0, 6)}...${addr.slice(-4)}`
}

const checkWalletConnection = async () => {
  try {
    if (window.ethereum) {
      const accounts = await window.ethereum.request({ method: 'eth_accounts' })
      isConnected.value = accounts && accounts.length > 0
      if (isConnected.value) {
        console.log('钱包已连接:', accounts[0])
        await loadNFTs()
      } else {
        console.log('钱包未连接')
      }
    }
  } catch (error) {
    console.error('检查钱包连接状态失败:', error)
  }
}

const getCurrentAccount = async () => {
  if (window.ethereum) {
    const accounts = await window.ethereum.request({ method: 'eth_accounts' })
    return accounts[0] || ''
  }
  return ''
}

const loadNFTs = async () => {
  if (hasLoadedHistory) return
  hasLoadedHistory = true
  console.log('开始查历史事件...')
  try {
    loading.value = true
    nfts.value = []
    error.value = null
    // 查最近200区块的所有事件
    const currentBlock = await publicClient.getBlockNumber()
    const fromBlock = currentBlock - 200n > 0n ? currentBlock - 200n : 0n
    const [listedLogs, boughtLogs, unlistedLogs] = await Promise.all([
      publicClient.getLogs({
        address: CONTRACT_ADDRESSES.NFTMarket,
        event: NFTMarketABI.find(e => e.name === 'NFTListed'),
        fromBlock,
        toBlock: 'latest'
      }),
      publicClient.getLogs({
        address: CONTRACT_ADDRESSES.NFTMarket,
        event: NFTMarketABI.find(e => e.name === 'NFTBought'),
        fromBlock,
        toBlock: 'latest'
      }),
      publicClient.getLogs({
        address: CONTRACT_ADDRESSES.NFTMarket,
        event: NFTMarketABI.find(e => e.name === 'NFTUnlisted'),
        fromBlock,
        toBlock: 'latest'
      })
    ])
    // 合并所有事件，按区块号+logIndex排序
    const allEvents = [
      ...listedLogs.map(log => ({ ...log, _type: 'listed' })),
      ...boughtLogs.map(log => ({ ...log, _type: 'bought' })),
      ...unlistedLogs.map(log => ({ ...log, _type: 'unlisted' }))
    ]
    allEvents.sort((a, b) => {
      if (a.blockNumber !== b.blockNumber) return a.blockNumber > b.blockNumber ? 1 : -1
      return a.logIndex > b.logIndex ? 1 : -1
    })
    // 重放事件，记录每个NFT的最新状态
    const nftState = new Map()
    for (const log of allEvents) {
      const key = `${log.args.nftContract.toLowerCase()}-${log.args.tokenId.toString()}`
      nftState.set(key, { log, type: log._type })
    }
    // 只显示最后状态为 listed 的NFT
    let foundByEvent = false
    for (const [key, { log, type }] of nftState.entries()) {
      if (type === 'listed') {
        foundByEvent = true
        const tokenId = log.args.tokenId.toString()
        let tokenURI = ''
        try {
          tokenURI = await publicClient.readContract({
            address: log.args.nftContract,
            abi: NFTABI,
            functionName: 'tokenURI',
            args: [BigInt(tokenId)]
          })
        } catch (e) {
          tokenURI = ''
        }
        nfts.value.push({
          id: tokenId,
          tokenId,
          tokenURI,
          price: formatEther(log.args.price),
          seller: log.args.seller,
          name: `NFT #${tokenId}`,
          image: `https://picsum.photos/seed/${tokenId}/400/400`
        })
      }
    }
    // 如果事件查不到任何NFT，补查链上listings（tokenId 1~10）
    if (!foundByEvent) {
      for (let tokenId = 1; tokenId <= 10; tokenId++) {
        try {
          const listing = await publicClient.readContract({
            address: CONTRACT_ADDRESSES.NFTMarket,
            abi: NFTMarketABI,
            functionName: 'listings',
            args: [CONTRACT_ADDRESSES.NFT, BigInt(tokenId)]
          })
          const isActive = listing.isActive ?? listing[2]
          if (isActive) {
            let tokenURI = ''
            try {
              tokenURI = await publicClient.readContract({
                address: CONTRACT_ADDRESSES.NFT,
                abi: NFTABI,
                functionName: 'tokenURI',
                args: [BigInt(tokenId)]
              })
            } catch (e) {
              tokenURI = ''
            }
            nfts.value.push({
              id: tokenId.toString(),
              tokenId: tokenId.toString(),
              tokenURI,
              price: formatEther(listing.price ?? listing[1]),
              seller: listing.seller ?? listing[0],
              name: `NFT #${tokenId}`,
              image: `https://picsum.photos/seed/${tokenId}/400/400`
            })
          }
        } catch (e) {
          // 忽略未上架或异常
        }
      }
    }
    console.log('allEvents', allEvents)
    console.log('nftState', nftState)
    console.log('nfts', nfts.value)
  } catch (err) {
    error.value = '加载 NFT 失败：' + (err.message || '未知错误')
    console.error(error.value)
    if (err && err.stack) console.error(err.stack)
  } finally {
    loading.value = false
  }
}

const buyNFT = async (tokenId) => {
  if (!isConnected.value) {
    console.log('钱包未连接，无法购买')
    return
  }

  try {
    isBuying.value = true
    error.value = null

    // 获取NFT价格和链上状态
    const listing = await publicClient.readContract({
      address: CONTRACT_ADDRESSES.NFTMarket,
      abi: NFTMarketABI,
      functionName: 'listings',
      args: [CONTRACT_ADDRESSES.NFT, BigInt(tokenId)]
    })
    console.log('购买前链上listing:', listing)
    const isActive = listing.isActive ?? listing[2]
    if (!isActive) {
      throw new Error('该NFT不在售')
    }

    const price = listing.price ?? listing[1]
    const seller = listing.seller ?? listing[0]

    const walletClient = getWalletClient()
    const accounts = await window.ethereum.request({ method: 'eth_accounts' })
    const currentAccount = accounts[0]

    // 1. 检查ERC20余额和授权
    const erc20Balance = await publicClient.readContract({
      address: CONTRACT_ADDRESSES.ERC20,
      abi: ERC20ABI,
      functionName: 'balanceOf',
      args: [currentAccount]
    })
    if (erc20Balance < price) {
      throw new Error('ERC20余额不足')
    }
    const allowance = await publicClient.readContract({
      address: CONTRACT_ADDRESSES.ERC20,
      abi: ERC20ABI,
      functionName: 'allowance',
      args: [currentAccount, CONTRACT_ADDRESSES.NFTMarket]
    })
    if (allowance < price) {
      // 先授权
      const approveHash = await walletClient.writeContract({
        address: CONTRACT_ADDRESSES.ERC20,
        abi: ERC20ABI,
        functionName: 'approve',
        args: [CONTRACT_ADDRESSES.NFTMarket, price],
        account: currentAccount
      })
      await publicClient.waitForTransactionReceipt({ hash: approveHash })
    }

    // 2. 购买NFT（不传value）
    const hash = await walletClient.writeContract({
      address: CONTRACT_ADDRESSES.NFTMarket,
      abi: NFTMarketABI,
      functionName: 'buyNFT',
      args: [CONTRACT_ADDRESSES.NFT, BigInt(tokenId)],
      account: currentAccount
    })

    console.log('交易已发送:', hash)
    // 等待交易确认
    const receipt = await publicClient.waitForTransactionReceipt({ hash })
    console.log('交易已确认:', receipt)
    // 刷新列表
    await loadNFTs()
    alert('购买成功！')
  } catch (error) {
    console.error('购买NFT失败:', error)
    alert(error.message || '购买NFT失败，请重试')
  } finally {
    isBuying.value = false
  }
}

const handleList = async () => {
  try {
    if (!isConnected.value) {
      alert('请先连接钱包')
      return
    }

    const accounts = await window.ethereum.request({ method: 'eth_accounts' })
    const currentAccount = accounts[0]

    if (!listForm.value.tokenId || !listForm.value.price) {
      alert('请填写完整信息')
      return
    }

    // 确保 tokenId 是数字
    const tokenId = parseInt(listForm.value.tokenId)
    if (isNaN(tokenId)) {
      alert('请输入有效的 NFT ID')
      return
    }

    // 确保价格是数字
    const price = parseFloat(listForm.value.price)
    if (isNaN(price)) {
      alert('请输入有效的价格')
      return
    }

    const priceInWei = parseEther(price.toString())

    // 检查 NFT 是否已经授权给市场合约
    const isApproved = await publicClient.readContract({
      address: CONTRACT_ADDRESSES.NFT,
      abi: NFTABI,
      functionName: 'isApprovedForAll',
      args: [currentAccount, CONTRACT_ADDRESSES.NFTMarket]
    })

    if (!isApproved) {
      // 如果未授权，先进行授权
      const { request } = await publicClient.simulateContract({
        address: CONTRACT_ADDRESSES.NFT,
        abi: NFTABI,
        functionName: 'setApprovalForAll',
        args: [CONTRACT_ADDRESSES.NFTMarket, true],
        account: currentAccount
      })
      const hash = await getWalletClient().writeContract(request)
      await publicClient.waitForTransactionReceipt({ hash })
    }

    // 上架 NFT
    const { request } = await publicClient.simulateContract({
      address: CONTRACT_ADDRESSES.NFTMarket,
      abi: NFTMarketABI,
      functionName: 'list',
      args: [CONTRACT_ADDRESSES.NFT, BigInt(tokenId), priceInWei],
      account: currentAccount
    })
    const hash = await getWalletClient().writeContract(request)
    await publicClient.waitForTransactionReceipt({ hash })

    // 重置表单
    listForm.value = {
      tokenId: '',
      price: ''
    }
    showListForm.value = false

    alert('NFT 上架成功！')
    await loadNFTs()
  } catch (error) {
    console.error('上架失败：', error)
    alert('上架失败：' + (error.message || '未知错误'))
  }
}

const removeNFT = async (tokenId) => {
  if (!isConnected.value) {
    console.log('钱包未连接，无法下架')
    return
  }

  try {
    isRemoving.value = true
    error.value = null

    // 始终查链上listings，兼容对象/数组结构
    const listing = await publicClient.readContract({
      address: CONTRACT_ADDRESSES.NFTMarket,
      abi: NFTMarketABI,
      functionName: 'listings',
      args: [CONTRACT_ADDRESSES.NFT, BigInt(tokenId)]
    })
    const isActive = listing.isActive ?? listing[2]
    if (!isActive) {
      throw new Error('该NFT未上架')
    }

    const accounts = await window.ethereum.request({ method: 'eth_accounts' })
    const currentAccount = accounts[0]

    if ((listing.seller ?? listing[0]).toLowerCase() !== currentAccount.toLowerCase()) {
      throw new Error('只有卖家可以下架NFT')
    }

    console.log('下架NFT:', {
      tokenId,
      seller: listing.seller ?? listing[0]
    })

    const walletClient = getWalletClient()
    // 下架NFT
    const hash = await walletClient.writeContract({
      address: CONTRACT_ADDRESSES.NFTMarket,
      abi: NFTMarketABI,
      functionName: 'unlist',
      args: [CONTRACT_ADDRESSES.NFT, BigInt(tokenId)],
      account: currentAccount
    })

    console.log('交易已发送:', hash)

    // 等待交易确认
    const receipt = await publicClient.waitForTransactionReceipt({ hash })
    console.log('交易已确认:', receipt)

    // 刷新列表
    await loadNFTs()
    alert('下架成功！')
  } catch (error) {
    console.error('下架NFT失败:', error)
    alert(error.message || '下架NFT失败，请重试')
  } finally {
    isRemoving.value = false
  }
}

onMounted(async () => {
  walletAddress.value = await getCurrentAccount()
  await checkWalletConnection()
  await loadNFTs()

  if (window.ethereum) {
    window.ethereum.on('chainChanged', () => {
      window.location.reload()
    })
    window.ethereum.on('accountsChanged', async (accounts) => {
      isConnected.value = accounts.length > 0
      walletAddress.value = accounts[0] || ''
      if (!isConnected.value) {
        nfts.value = []
      }
    })
  }
})
</script>

<style scoped>
.nft-market {
  padding: 2rem;
  max-width: 1200px;
  margin: 0 auto;
}

.market-container {
  background: #fff;
  border-radius: 12px;
  padding: 2rem;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

.market-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 2rem;
  padding-bottom: 1rem;
  border-bottom: 1px solid #eee;
}

.market-header h2 {
  margin: 0;
  color: #333;
  font-size: 1.5rem;
}

.list-btn {
  background-color: #4CAF50;
  color: white;
  padding: 0.75rem 1.5rem;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  font-weight: bold;
  font-size: 1rem;
  transition: all 0.2s;
}

.list-btn:hover {
  background-color: #45a049;
  transform: translateY(-1px);
}

.list-form-container {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 1000;
}

.list-form {
  background: white;
  padding: 2rem;
  border-radius: 12px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
  width: 100%;
  max-width: 500px;
  position: relative;
}

.form-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1.5rem;
}

.form-header h3 {
  margin: 0;
  color: #333;
}

.close-btn {
  background: none;
  border: none;
  font-size: 1.5rem;
  color: #666;
  cursor: pointer;
  padding: 0.5rem;
  line-height: 1;
}

.close-btn:hover {
  color: #333;
}

.nft-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 2rem;
  margin-top: 2rem;
}

.nft-card {
  background: white;
  border-radius: 12px;
  overflow: hidden;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05);
  transition: all 0.3s ease;
  border: 1px solid #eee;
}

.nft-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
}

.nft-image-container {
  position: relative;
  padding-top: 100%;
  overflow: hidden;
}

.nft-image {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.nft-info {
  padding: 1.5rem;
}

.nft-info h3 {
  margin: 0 0 1rem 0;
  color: #333;
  font-size: 1.25rem;
}

.price {
  color: #4CAF50;
  font-weight: bold;
  font-size: 1.2rem;
  margin: 0.5rem 0;
}

.seller {
  color: #666;
  font-size: 0.9rem;
  margin: 0.5rem 0 1rem 0;
}

.buy-btn, .remove-btn {
  width: 100%;
  padding: 0.75rem;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  font-weight: bold;
  font-size: 1rem;
  transition: all 0.2s;
}

.buy-btn {
  background-color: #4CAF50;
  color: white;
}

.buy-btn:hover {
  background-color: #45a049;
}

.buy-btn:disabled {
  background-color: #cccccc;
  cursor: not-allowed;
}

.remove-btn {
  background-color: #f44336;
  color: white;
}

.remove-btn:hover {
  background-color: #d32f2f;
}

.form-group {
  margin-bottom: 1.5rem;
}

.form-group label {
  display: block;
  margin-bottom: 0.5rem;
  color: #666;
  font-weight: 500;
}

.form-group input {
  width: 100%;
  padding: 0.75rem;
  border: 1px solid #ddd;
  border-radius: 6px;
  font-size: 1rem;
  transition: border-color 0.2s;
}

.form-group input:focus {
  outline: none;
  border-color: #4CAF50;
}

.form-buttons {
  display: flex;
  gap: 1rem;
  margin-top: 2rem;
}

.submit-btn, .cancel-btn {
  flex: 1;
  padding: 0.75rem;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  font-weight: bold;
  font-size: 1rem;
  transition: all 0.2s;
}

.submit-btn {
  background-color: #4CAF50;
  color: white;
}

.submit-btn:hover {
  background-color: #45a049;
}

.submit-btn:disabled {
  background-color: #cccccc;
  cursor: not-allowed;
}

.cancel-btn {
  background-color: #f5f5f5;
  color: #666;
}

.cancel-btn:hover {
  background-color: #e0e0e0;
}

@media (max-width: 1024px) {
  .nft-grid {
    grid-template-columns: repeat(2, 1fr);
  }
}

@media (max-width: 768px) {
  .nft-grid {
    grid-template-columns: 1fr;
  }
  
  .nft-market {
    padding: 1rem;
  }
}
</style> 