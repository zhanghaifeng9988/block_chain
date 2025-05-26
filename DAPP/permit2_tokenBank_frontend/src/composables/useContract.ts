import { useContract as useViemContract } from 'viem';
import { useWallet } from './useWallet';

export function useContract(address: string, abi: any) {
  const { signer } = useWallet();
  return useViemContract({
    address,
    abi,
    signer,
  });
} 