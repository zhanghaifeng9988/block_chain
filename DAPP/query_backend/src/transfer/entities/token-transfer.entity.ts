import {
  Entity,
  Column,
  PrimaryGeneratedColumn,
  CreateDateColumn,
} from 'typeorm';

@Entity('token_transfers')
export class TokenTransfer {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ length: 42 })
  from_address: string;

  @Column({ length: 42 })
  to_address: string;

  @Column('decimal', { precision: 78, scale: 0 })
  amount: string;

  @Column({ length: 66 })
  transaction_hash: string;

  @Column('bigint')
  block_number: number;

  @Column()
  timestamp: Date;

  @CreateDateColumn()
  created_at: Date;
}
