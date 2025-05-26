<template>
  <div>
    <h2>Token Balance: {{ tokenBalance }}</h2>
    <h2>Bank Balance: {{ bankBalance }}</h2>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import { useContract } from '../composables/useContract';
import { TOKEN_ADDRESS, PERMIT2_ADDRESS } from '../contracts/addresses';

const tokenBalance = ref(0);
const bankBalance = ref(0);

onMounted(async () => {
  const tokenContract = useContract(TOKEN_ADDRESS, []);
  const bankContract = useContract(PERMIT2_ADDRESS, []);

  // 获取代币余额
  tokenBalance.value = await tokenContract.balanceOf();
  // 获取银行余额
  bankBalance.value = await bankContract.getBankBalance();
});
</script>

<style scoped>
h2 {
  margin: 10px 0;
}
</style> 