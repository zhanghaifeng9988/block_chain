import { createPublicClient, http, createWalletClient, custom, webSocket } from 'viem'
import { sepolia } from 'viem/chains'
import { NFTMarketABI, NFTABI, CONTRACT_ADDRESSES } from '../contracts/abi'

// 创建公共客户端
export const publicClient = createPublicClient({
  chain: sepolia,
  transport: http('https://sepolia.infura.io/v3/b2affe5792cd45bd9b462e8762d352f2')
})

// WebSocket可选，如需实时监听可用Merkl或注释掉
export const wsClient = createPublicClient({
  chain: sepolia,
  transport: webSocket('wss://sepolia.infura.io/ws/v3/b2affe5792cd45bd9b462e8762d352f2')
})

// 创建钱包客户端
export const getWalletClient = () => {
  if (!window.ethereum) {
    throw new Error('MetaMask not installed')
  }

  return createWalletClient({
    chain: sepolia,
    transport: custom(window.ethereum)
  })
}

// 导出合约地址和 ABI
export { CONTRACT_ADDRESSES, NFTMarketABI, NFTABI }

// 合约交互函数
export const contractUtils = {
  // 获取所有上架的NFT
  async getAllListings() {
    try {
      const data = await publicClient.readContract({
        address: CONTRACT_ADDRESSES.NFTMarket,
        abi: NFTMarketABI,
        functionName: 'getAllListings'
      })
      return data
    } catch (error) {
      console.error('获取NFT列表失败:', error)
      throw error
    }
  },

  // 上架NFT
  async listNFT(tokenId, price) {
    try {
      const walletClient = getWalletClient()
      const hash = await walletClient.writeContract({
        address: CONTRACT_ADDRESSES.NFTMarket,
        abi: NFTMarketABI,
        functionName: 'listNFT',
        args: [tokenId, price]
      })
      return hash
    } catch (error) {
      console.error('上架NFT失败:', error)
      throw error
    }
  },

  // 购买NFT
  async buyNFT(tokenId, value) {
    try {
      const walletClient = getWalletClient()
      const hash = await walletClient.writeContract({
        address: CONTRACT_ADDRESSES.NFTMarket,
        abi: NFTMarketABI,
        functionName: 'buyNFT',
        args: [tokenId],
        value
      })
      return hash
    } catch (error) {
      console.error('购买NFT失败:', error)
      throw error
    }
  },

  // 铸造NFT
  async mintNFT(to, tokenId, uri) {
    try {
      const walletClient = getWalletClient()
      const hash = await walletClient.writeContract({
        address: CONTRACT_ADDRESSES.NFT,
        abi: NFTABI,
        functionName: 'mint',
        args: [to, tokenId, uri]
      })
      return hash
    } catch (error) {
      console.error('铸造NFT失败:', error)
      throw error
    }
  },

  // 获取NFT所有者
  async getNFTOwner(tokenId) {
    try {
      const data = await publicClient.readContract({
        address: CONTRACT_ADDRESSES.NFT,
        abi: NFTABI,
        functionName: 'ownerOf',
        args: [tokenId]
      })
      return data
    } catch (error) {
      console.error('获取NFT所有者失败:', error)
      throw error
    }
  },

  // 获取NFT URI
  async getNFTURI(tokenId) {
    try {
      const data = await publicClient.readContract({
        address: CONTRACT_ADDRESSES.NFT,
        abi: NFTABI,
        functionName: 'tokenURI',
        args: [tokenId]
      })
      return data
    } catch (error) {
      console.error('获取NFT URI失败:', error)
      throw error
    }
  }
} 