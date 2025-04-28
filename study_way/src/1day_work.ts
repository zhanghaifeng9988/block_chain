import { createHash } from 'crypto';

// 设置昵称
const nickname = 'zhanghaifeng';

// 主程序
function test() {
  const zeroCounts = [4, 5]; // 分别寻找 4 个零和 5 个零开头的哈希值

  for (const zeroCount of zeroCounts) {
    let nonce = 0;
    const startTime = Date.now(); // 开始时间

    while (true) {
      const hash = createHash('sha256').update(nickname + nonce).digest('hex'); // 计算哈希值
      if (hash.startsWith('0'.repeat(zeroCount))) {
        const endTime = Date.now(); // 结束时间
        console.log(`找到满足 ${zeroCount} 个零开头的哈希值：`);
        console.log(`Nonce: ${nonce}`);
        console.log(`Hash: ${hash}`);
        console.log(`耗时: ${endTime - startTime} ms`);
        console.log('--------------------------------');
        break;
      }
      nonce++;
    }
  }
}

test();