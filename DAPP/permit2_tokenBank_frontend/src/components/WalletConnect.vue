<template>
  <button @click="connectWallet">Connect Wallet</button>
</template>

<script setup>
import { useWalletStore } from '../stores/wallet';

const walletStore = useWalletStore();

async function connectWallet() {
  await walletStore.connect();
}
</script>

<style scoped>
button {
  padding: 10px 20px;
  background-color: #4CAF50;
  color: white;
  border: none;
  border-radius: 5px;
  cursor: pointer;
}
</style> 