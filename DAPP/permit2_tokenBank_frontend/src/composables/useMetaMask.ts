import { ref } from 'vue'

export function useMetaMask() {
  const address = ref<string | null>(null)
  const isConnected = ref(false)

  // 检查是否已连接
  const checkConnection = async () => {
    if ((window as any).ethereum) {
      const accounts = await (window as any).ethereum.request({ method: 'eth_accounts' })
      if (accounts.length > 0) {
        address.value = accounts[0]
        isConnected.value = true
      }
    }
  }

  // 主动连接
  const connect = async () => {
    if ((window as any).ethereum) {
      const accounts = await (window as any).ethereum.request({ method: 'eth_requestAccounts' })
      address.value = accounts[0]
      isConnected.value = true
    } else {
      alert('请先安装MetaMask插件')
    }
  }

  // 断开连接（只是前端清空，不会让MetaMask断开授权）
  const disconnect = () => {
    address.value = null
    isConnected.value = false
  }

  return { address, isConnected, connect, disconnect, checkConnection }
} 