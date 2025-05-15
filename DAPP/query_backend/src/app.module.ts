import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { TransferModule } from './transfer/transfer.module';
import { TokenTransfer } from './transfer/entities/token-transfer.entity';

@Module({
  imports: [
    TypeOrmModule.forRoot({
      type: 'postgres',
      host: '192.168.0.111',
      port: 5432,
      username: 'zhf',
      password: '123123',
      database: 'zhf_db',
      entities: [TokenTransfer],
      synchronize: true, // 开发环境使用，生产环境建议关闭
    }),
    TransferModule,
  ],
})
export class AppModule {}
