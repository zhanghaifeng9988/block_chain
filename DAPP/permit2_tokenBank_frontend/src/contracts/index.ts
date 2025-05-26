import { createPublicClient, createWalletClient, custom, parseEther, formatEther } from 'viem'
import { hardhat } from 'viem/chains'
import { PERMIT2_TOKEN_ADDRESS, PERMIT2_ADDRESS, PERMIT2_TOKEN_BANK_ADDRESS } from './addresses'
import Permit2TokenABI from './abis/Permit2Token.json'
import Permit2TokenBankABI from './abis/Permit2TokenBank.json'
import Permit2ABI from './abis/Permit2.json'

// 创建公共客户端
export const publicClient = createPublicClient({
  chain: hardhat,
  transport: custom(window.ethereum as any)
})

// 创建钱包客户端
export const walletClient = createWalletClient({
  chain: hardhat,
  transport: custom(window.ethereum as any)
})

// 创建合约实例
export const permit2TokenContract = {
  address: PERMIT2_TOKEN_ADDRESS,
  abi: Permit2TokenABI
}

export const permit2TokenBankContract = {
  address: PERMIT2_TOKEN_BANK_ADDRESS,
  abi: Permit2TokenBankABI
}

export const permit2Contract = {
  address: PERMIT2_ADDRESS,
  abi: Permit2ABI
}

export { PERMIT2_ADDRESS }

// 辅助函数：格式化金额
export const formatAmount = (amount: bigint) => {
  return formatEther(amount)
}

// 辅助函数：解析金额
export const parseAmount = (amount: string | number) => {
  return parseEther(amount.toString())
} 