// 需要先安装 viem: npm install viem

const { createPublicClient, http, getStorageAt } = require('viem');
const { parseAbi } = require('viem');

// esRNT合约地址
const contractAddress = '0x5FbDB2315678afecb367f032d93F642f64180aa3';
// 本地anvil节点
const rpcUrl = 'http://127.0.0.1:8545';

// _locks数组的slot位置，solidity中第一个声明的状态变量slot为0
const locksSlot = 0;
// _locks数组长度
const locksLength = 11;

// viem客户端
const client = createPublicClient({
  transport: http(rpcUrl),
});

// 解析LockInfo结构体
function decodeLockInfo(hex) {
  // LockInfo结构体: address(20字节) + uint64(8字节) + uint256(32字节)
  // 总共60字节，solidity会填充为32字节对齐的多个slot
  // 这里每个LockInfo占用2个slot
  // slot0: address(20字节) + uint64(8字节) + uint256高位4字节
  // slot1: uint256低位28字节
  // 但实际solidity会将address和uint64分别单独存储
  // 所以我们需要分别读取每个成员
  // 但这里我们直接读取每个slot的内容
  return hex;
}

// 计算数组元素的slot位置
function getLockSlot(baseSlot, index) {
  // keccak256(baseSlot) + index
  const { keccak256, toHex } = require('viem');
  const base = keccak256(toHex(baseSlot, { size: 32 }));
  return BigInt(base) + BigInt(index);
}

async function main() {
  const { keccak256, toHex, hexToBigInt, hexToNumber, hexToString, hexToAddress } = require('viem');
  for (let i = 0; i < locksLength; i++) {
    // 计算slot
    const slot = getLockSlot(locksSlot, i);
    // 读取user
    const userHex = await client.getStorageAt({ address: contractAddress, slot: toHex(slot, { size: 32 }) });
    // 读取startTime
    const startTimeSlot = slot + 1n;
    const startTimeHex = await client.getStorageAt({ address: contractAddress, slot: toHex(startTimeSlot, { size: 32 }) });
    // 读取amount
    const amountSlot = slot + 2n;
    const amountHex = await client.getStorageAt({ address: contractAddress, slot: toHex(amountSlot, { size: 32 }) });

    // 解析user
    const user = '0x' + userHex.slice(26);
    // 解析startTime
    const startTime = Number(startTimeHex);
    // 解析amount
    const amount = BigInt(amountHex);

    console.log(`locks[${i}]: user: ${user}, startTime: ${startTime}, amount: ${amount}`);
  }
}

main().catch(console.error); 