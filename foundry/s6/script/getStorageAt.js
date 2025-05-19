// 需要先安装 viem: npm install viem
const { createPublicClient, http, toHex, keccak256 } = require('viem');

// esRNT合约地址
const contractAddress = '0x5FbDB2315678afecb367f032d93F642f64180aa3';
// 本地anvil节点
const rpcUrl = 'http://127.0.0.1:8545';

// _locks数组的slot位置（solidity中第一个状态变量slot为0）
const locksSlot = 0;
// _locks数组长度
const locksLength = 11;

// viem客户端
const client = createPublicClient({
  transport: http(rpcUrl),
});

// 计算数组元素的slot位置
function getLockSlot(baseSlot, index) {
  const base = keccak256(toHex(baseSlot, { size: 32 }));
  return BigInt(base) + BigInt(index);
}

async function main() {
  const results = [];
  
  for (let i = 0; i < locksLength; i++) {
    try {
      const slot = getLockSlot(locksSlot, i);
      
      // 读取user (address)
      const userHex = await client.getStorageAt({ 
        address: contractAddress, 
        slot: toHex(slot, { size: 32 }) 
      });
      const user = userHex ? '0x' + userHex.slice(26) : '0x0';
      
      // 读取startTime (uint64)
      const startTimeSlot = slot + 1n;
      const startTimeHex = await client.getStorageAt({ 
        address: contractAddress, 
        slot: toHex(startTimeSlot, { size: 32 }) 
      });
      const startTime = startTimeHex ? Number(startTimeHex) : 0;
      
      // 读取amount (uint256)
      const amountSlot = slot + 2n;
      const amountHex = await client.getStorageAt({ 
        address: contractAddress, 
        slot: toHex(amountSlot, { size: 32 }) 
      });
      const amount = amountHex ? BigInt(amountHex) : 0n;

      results.push(`locks[${i}]: user: ${user}, startTime: ${startTime}, amount: ${amount}`);
    } catch (error) {
      results.push(`Error reading locks[${i}]: ${error.message}`);
    }
  }

  // 统一输出结果（避免多次console.log影响重定向）
  console.log(results.join('\n'));
}

main().catch((error) => {
  console.error('Script failed:', error);
  process.exit(1);
});
