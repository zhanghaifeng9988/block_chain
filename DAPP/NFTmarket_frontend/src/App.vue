<script setup>
import { useWallet } from 'vue-dapp'
import WalletConnect from './components/WalletConnect.vue'
import NFTMarket from './components/NFTMarket.vue'
import NFTMint from './components/NFTMint.vue'

const { isConnected } = useWallet()
</script>

<template>
  <div class="app">
    <header>
      <h1>NFT 市场</h1>
      <WalletConnect />
    </header>
    <main>
      <NFTMarket />
    </main>
  </div>
</template>

<style>
.app {
  max-width: 1200px;
  margin: 0 auto;
  padding: 20px;
}

header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 2rem;
  padding: 1rem;
  background-color: #f8f9fa;
  border-radius: 8px;
}

h1 {
  margin: 0;
  color: #333;
}

main {
  background-color: #fff;
  border-radius: 8px;
  padding: 2rem;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}
</style>
