import { parseSignature as parseViemSignature } from 'viem'
 
export function parseSignature(signature: `0x${string}`) {
  return parseViemSignature(signature)
} 