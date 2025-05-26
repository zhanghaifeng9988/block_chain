<template>
  <div>
    <h2>Deposit</h2>
    <input v-model="amount" type="number" placeholder="Amount" />
    <button @click="deposit">Deposit</button>
    <button @click="permit2Deposit">Permit2 Deposit</button>
    <button @click="permitDeposit">Permit Deposit</button>
  </div>
</template>

<script setup>
import { ref } from 'vue';
import { useContract } from '../composables/useContract';
import { TOKEN_ADDRESS, PERMIT2_ADDRESS } from '../contracts/addresses';

const amount = ref(0);

async function deposit() {
  const tokenContract = useContract(TOKEN_ADDRESS, []);
  await tokenContract.deposit(amount.value);
}

async function permit2Deposit() {
  const bankContract = useContract(PERMIT2_ADDRESS, []);
  await bankContract.depositWithPermit2(amount.value);
}

async function permitDeposit() {
  const bankContract = useContract(PERMIT2_ADDRESS, []);
  await bankContract.permitDeposit(amount.value);
}
</script>

<style scoped>
input {
  margin: 10px 0;
  padding: 5px;
}
button {
  margin: 5px;
  padding: 10px 20px;
  background-color: #4CAF50;
  color: white;
  border: none;
  border-radius: 5px;
  cursor: pointer;
}
</style> 