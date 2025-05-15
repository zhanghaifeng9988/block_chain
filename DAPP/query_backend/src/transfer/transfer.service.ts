import { Injectable, OnModuleInit } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { TokenTransfer } from './entities/token-transfer.entity';
import { createPublicClient, http, parseAbiItem } from 'viem';
import { sepolia } from 'viem/chains';

@Injectable()
export class TransferService implements OnModuleInit {
  private client;
  private readonly tokenAddress = '0xa740eE38BB16e25fd0417f57e00119eb99a05127'; // 替换为实际的代币合约地址

  constructor(
    @InjectRepository(TokenTransfer)
    private transferRepository: Repository<TokenTransfer>,
  ) {
    // 初始化viem客户端
    this.client = createPublicClient({
      chain: sepolia, // 这里使用Sepolia测试网，可以根据需要更改
      transport: http(
        'https://sepolia.infura.io/v3/b2affe5792cd45bd9b462e8762d352f2',
      ), // 替换为你的RPC节点URL
    });
  }

  async onModuleInit() {
    // 模块初始化时开始监听转账事件
    await this.startListening();
  }

  private async startListening() {
    // 定义Transfer事件的ABI
    const transferEvent = parseAbiItem(
      'event Transfer(address indexed from, address indexed to, uint256 value)',
    );

    // 开始监听事件
    this.client.watchEvent({
      address: this.tokenAddress,
      event: transferEvent,
      onLogs: async (logs) => {
        for (const log of logs) {
          // 创建新的转账记录
          const transfer = new TokenTransfer();
          transfer.from_address = log.args.from;
          transfer.to_address = log.args.to;
          transfer.amount = log.args.value.toString();
          transfer.transaction_hash = log.transactionHash;
          transfer.block_number = Number(log.blockNumber);

          // 获取区块时间戳
          const block = await this.client.getBlock({
            blockNumber: log.blockNumber,
          });
          transfer.timestamp = new Date(Number(block.timestamp) * 1000);

          // 保存到数据库
          await this.transferRepository.save(transfer);

          console.log(
            `已记录转账: ${transfer.from_address} -> ${transfer.to_address}, 金额: ${transfer.amount}`,
          );
        }
      },
    });

    console.log('开始监听转账事件...');
  }
}
