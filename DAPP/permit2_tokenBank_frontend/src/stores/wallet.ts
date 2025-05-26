import { defineStore } from 'pinia';
import { useWallet } from '../composables/useWallet';

export const useWalletStore = defineStore('wallet', {
  state: () => ({
    address: '',
    isConnected: false,
  }),
  actions: {
    async connect() {
      const { address, isConnected } = useWallet();
      this.address = address;
      this.isConnected = isConnected;
    },
  },
}); 