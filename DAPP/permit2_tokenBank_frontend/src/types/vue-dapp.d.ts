import { WalletClient } from 'viem'

declare module 'vue-dapp' {
  export interface WalletState {
    address: string
    chainId: number
    isConnected: boolean
  }

  export function useWallet(): {
    wallet: WalletState
    connect: () => Promise<void>
    disconnect: () => void
  }
} 