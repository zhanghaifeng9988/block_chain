<script setup>
import { ref } from 'vue'
import WalletConnect from './components/WalletConnect.vue'
import TransferRecords from './components/TransferRecords.vue'

const transferRecordsRef = ref(null)

// 处理钱包连接成功
const handleWalletConnected = (address) => {
  if (transferRecordsRef.value) {
    transferRecordsRef.value.searchByConnectedWallet(address)
  }
}
</script>

<template>
  <div class="app">
    <header class="header">
      <div class="header-content">
        <h1>Token转账记录查询</h1>
        <WalletConnect @wallet-connected="handleWalletConnected" />
      </div>
    </header>
    <main class="main-content">
      <TransferRecords ref="transferRecordsRef" />
    </main>
    <footer class="footer">
      <p>© 2024 Token Transfer Explorer</p>
    </footer>
  </div>
</template>

<style>
:root {
  --primary-color: #409EFF;
  --background-color: #f5f7fa;
  --header-height: 80px;
}

body {
  margin: 0;
  padding: 0;
  background-color: var(--background-color);
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
}

.app {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
}

.header {
  background: white;
  box-shadow: 0 2px 12px 0 rgba(0, 0, 0, 0.1);
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  z-index: 100;
}

.header-content {
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 20px;
  height: var(--header-height);
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.header h1 {
  color: var(--primary-color);
  margin: 0;
  font-size: 24px;
}

.main-content {
  max-width: 1200px;
  margin: var(--header-height) auto 0;
  padding: 20px;
  flex: 1;
}

.footer {
  background: white;
  padding: 20px;
  text-align: center;
  color: #666;
  box-shadow: 0 -2px 12px 0 rgba(0, 0, 0, 0.1);
}

@media (max-width: 768px) {
  .header-content {
    flex-direction: column;
    height: auto;
    padding: 10px 20px;
  }

  .header h1 {
    margin-bottom: 10px;
  }

  .main-content {
    margin-top: calc(var(--header-height) + 20px);
  }
}
</style>
