import { Controller, Get, Query } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { TokenTransfer } from './entities/token-transfer.entity';

@Controller('transfer')
export class TransferController {
  constructor(
    @InjectRepository(TokenTransfer)
    private transferRepository: Repository<TokenTransfer>,
  ) {}

  @Get('by-address')
  async getTransfersByAddress(
    @Query('address') address: string,
    @Query('page') page = 1,
    @Query('limit') limit = 10,
  ) {
    const skip = (page - 1) * limit;

    const [transfers, total] = await this.transferRepository.findAndCount({
      where: [{ from_address: address }, { to_address: address }],
      order: { block_number: 'DESC' },
      skip,
      take: limit,
    });

    return {
      transfers,
      total,
      page,
      limit,
    };
  }

  @Get('by-hash')
  async getTransferByHash(@Query('hash') hash: string) {
    return this.transferRepository.findOne({
      where: { transaction_hash: hash },
    });
  }

  @Get()
  async getAllTransfers(@Query('page') page = 1, @Query('limit') limit = 10) {
    const skip = (page - 1) * limit;

    const [transfers, total] = await this.transferRepository.findAndCount({
      order: { block_number: 'DESC' },
      skip,
      take: limit,
    });

    return {
      transfers,
      total,
      page,
      limit,
    };
  }
}
