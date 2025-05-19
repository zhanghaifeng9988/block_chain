<template>
  <div class="nft-mint">
    <h2>铸造 NFT</h2>
    <div class="mint-form">
      <div class="form-group">
        <label>NFT 名称</label>
        <input 
          v-model="nftName" 
          type="text" 
          placeholder="输入 NFT 名称"
          :disabled="isMinting"
        >
      </div>
      
      <div class="form-group">
        <label>NFT 描述</label>
        <textarea 
          v-model="nftDescription" 
          placeholder="输入 NFT 描述"
          :disabled="isMinting"
        ></textarea>
      </div>

      <div class="form-group">
        <label>NFT 图片</label>
        <input 
          type="file" 
          accept="image/*"
          @change="handleImageUpload"
          :disabled="isMinting"
        >
      </div>

      <div class="form-group">
        <label>上架价格 (ETH)</label>
        <input 
          v-model="price" 
          type="number" 
          step="0.01"
          min="0"
          placeholder="输入上架价格"
          :disabled="isMinting"
        >
      </div>

      <button 
        @click="mintNFT" 
        class="mint-btn"
        :disabled="isMinting || !canMint"
      >
        {{ isMinting ? '铸造中...' : '铸造并上架' }}
      </button>
    </div>

    <div v-if="error" class="error-message">
      {{ error }}
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useWallet } from 'vue-dapp'
import { parseEther } from 'viem'
import { CONTRACT_ADDRESSES, NFTABI, NFTMarketABI } from '../contracts/abi'

const { address, provider } = useWallet()

const nftName = ref('')
const nftDescription = ref('')
const nftImage = ref(null)
const price = ref('')
const isMinting = ref(false)
const error = ref(null)

const canMint = computed(() => {
  return nftName.value && 
         nftDescription.value && 
         nftImage.value && 
         price.value > 0
})

const handleImageUpload = (event) => {
  const file = event.target.files[0]
  if (file) {
    nftImage.value = file
  }
}

const mintNFT = async () => {
  if (!provider || !address.value) {
    error.value = '请先连接钱包'
    return
  }

  try {
    isMinting.value = true
    error.value = null

    // 1. 上传图片到 IPFS（这里需要实现）
    // const imageUrl = await uploadToIPFS(nftImage.value)

    // 2. 创建 NFT 元数据
    const metadata = {
      name: nftName.value,
      description: nftDescription.value,
      image: 'https://example.com/placeholder.jpg' // 替换为实际的 IPFS URL
    }

    // 3. 上传元数据到 IPFS（这里需要实现）
    // const metadataUrl = await uploadToIPFS(metadata)

    // 4. 铸造 NFT
    const nftContract = {
      address: CONTRACT_ADDRESSES.NFT,
      abi: NFTABI
    }

    // 5. 授权 NFT 市场合约
    await provider.writeContract({
      ...nftContract,
      functionName: 'setApprovalForAll',
      args: [CONTRACT_ADDRESSES.NFTMarket, true]
    })

    // 6. 上架 NFT
    const marketContract = {
      address: CONTRACT_ADDRESSES.NFTMarket,
      abi: NFTMarketABI
    }

    await provider.writeContract({
      ...marketContract,
      functionName: 'list',
      args: [
        CONTRACT_ADDRESSES.NFT,
        1, // 这里需要替换为实际的 tokenId
        parseEther(price.value)
      ]
    })

    // 清空表单
    nftName.value = ''
    nftDescription.value = ''
    nftImage.value = null
    price.value = ''

    alert('NFT 铸造并上架成功！')
  } catch (error) {
    console.error('铸造 NFT 失败:', error)
    error.value = '铸造 NFT 失败，请重试'
  } finally {
    isMinting.value = false
  }
}
</script>

<style scoped>
.nft-mint {
  max-width: 600px;
  margin: 0 auto;
  padding: 2rem;
}

.mint-form {
  background: white;
  padding: 2rem;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

.form-group {
  margin-bottom: 1.5rem;
}

.form-group label {
  display: block;
  margin-bottom: 0.5rem;
  font-weight: bold;
  color: #333;
}

.form-group input,
.form-group textarea {
  width: 100%;
  padding: 0.75rem;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 1rem;
}

.form-group textarea {
  height: 100px;
  resize: vertical;
}

.mint-btn {
  width: 100%;
  padding: 1rem;
  background-color: #4CAF50;
  color: white;
  border: none;
  border-radius: 4px;
  font-size: 1rem;
  font-weight: bold;
  cursor: pointer;
  transition: background-color 0.2s;
}

.mint-btn:hover {
  background-color: #45a049;
}

.mint-btn:disabled {
  background-color: #cccccc;
  cursor: not-allowed;
}

.error-message {
  color: #f44336;
  padding: 1rem;
  margin-top: 1rem;
  background-color: #ffebee;
  border-radius: 4px;
}
</style> 