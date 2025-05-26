import { ref, Ref } from 'vue'
import { useWallet } from 'vue-dapp'
import { publicClient, walletClient, permit2TokenContract, permit2TokenBankContract, formatAmount, parseAmount, PERMIT2_ADDRESS, permit2Contract } from '../contracts'
import { parseSignature } from '../utils/signature'

export function useTokenBank(addressRef: Ref<string | null>) {
  const { wallet } = useWallet()
  const tokenBalance = ref('0')
  const bankBalance = ref('0')
  const isLoading = ref(false)

  // 获取代币余额
  const getTokenBalance = async () => {
    if (!addressRef.value) return
    try {
      const balance = await publicClient.readContract({
        address: permit2TokenContract.address as `0x${string}`,
        abi: permit2TokenContract.abi,
        functionName: 'balanceOf',
        args: [addressRef.value as `0x${string}`]
      })
      tokenBalance.value = formatAmount(balance as bigint)
    } catch (error) {
      console.error('获取代币余额失败:', error)
    }
  }

  // 获取银行余额
  const getBankBalance = async () => {
    if (!addressRef.value) return
    try {
      const balance = await publicClient.readContract({
        address: permit2TokenBankContract.address as `0x${string}`,
        abi: permit2TokenBankContract.abi,
        functionName: 'getDepositRecord',
        args: [addressRef.value as `0x${string}`]
      })
      bankBalance.value = formatAmount(balance as bigint)
    } catch (error) {
      console.error('获取银行余额失败:', error)
    }
  }

  // 普通存款
  const deposit = async (amount: string) => {
    if (!addressRef.value) return
    isLoading.value = true
    try {
      // 先授权
      const approveHash = await walletClient.writeContract({
        account: addressRef.value as `0x${string}`,
        address: permit2TokenContract.address as `0x${string}`,
        abi: permit2TokenContract.abi,
        functionName: 'approve',
        args: [permit2TokenBankContract.address as `0x${string}`, parseAmount(amount)]
      })
      await publicClient.waitForTransactionReceipt({ hash: approveHash })

      // 存款
      const hash = await walletClient.writeContract({
        account: addressRef.value as `0x${string}`,
        address: permit2TokenBankContract.address as `0x${string}`,
        abi: permit2TokenBankContract.abi,
        functionName: 'deposit',
        args: [parseAmount(amount)]
      })
      await publicClient.waitForTransactionReceipt({ hash })

      // 更新余额
      await Promise.all([getTokenBalance(), getBankBalance()])
    } catch (error) {
      console.error('存款失败:', error)
    } finally {
      isLoading.value = false
    }
  }

  // Permit2 授权
  const permit2Approve = async (amount: string) => {
    if (!addressRef.value) return
    isLoading.value = true
    try {
      // 直接对 Permit2 合约授权
      const approveHash = await walletClient.writeContract({
        account: addressRef.value as `0x${string}`,
        address: permit2TokenContract.address as `0x${string}`,
        abi: permit2TokenContract.abi,
        functionName: 'approve',
        args: [PERMIT2_ADDRESS as `0x${string}`, parseAmount(amount)]
      })
      await publicClient.waitForTransactionReceipt({ hash: approveHash })
      await getTokenBalance()
    } catch (error) {
      console.error('Permit2 授权失败:', error)
    } finally {
      isLoading.value = false
    }
  }

  // 使用 Permit2 存款
  const depositWithPermit2 = async (amount: string | number) => {
    console.log('=== 开始 Permit2 存款 ===')
    try {
      const parsedAmount = parseAmount(amount)
      const address = addressRef.value
      console.log('用户地址', address)

      // 获取 nonce
      const nonceBitmap = await publicClient.readContract({
        address: permit2Contract.address as `0x${string}`,
        abi: permit2Contract.abi,
        functionName: 'nonceBitmap',
        args: [address as `0x${string}`, 0] // 使用wordPos 0
      })
      console.log('nonceBitmap', nonceBitmap)

      // 获取当前区块时间戳
      const block = await publicClient.getBlock()
      const blockTimestamp = block.timestamp

      // 构建 permit 结构（所有数值字段用 BigInt，彻底兼容 viem）
      const permit = {
        permitted: {
          token: permit2TokenContract.address as `0x${string}`,
          amount: BigInt(parsedAmount)
        },
        nonce: BigInt(nonceBitmap as bigint),
        deadline: BigInt(blockTimestamp) + BigInt(3600 * 24 * 365) // 使用区块时间戳 + 1年
      }
      console.log('permit', permit)

      // 签名数据（Uniswap Permit2 标准）
      const signature = await walletClient.signTypedData({
        account: address as `0x${string}`,
        domain: {
          name: 'Permit2',
          chainId: 31337,
          verifyingContract: PERMIT2_ADDRESS as `0x${string}`
        },
        types: {
          TokenPermissions: [
            { name: 'token', type: 'address' },
            { name: 'amount', type: 'uint256' }
          ],
          PermitTransferFrom: [
            { name: 'permitted', type: 'TokenPermissions' },
            { name: 'nonce', type: 'uint256' },
            { name: 'deadline', type: 'uint256' }
          ]
        },
        primaryType: 'PermitTransferFrom',
        message: permit
      })
      console.log('signature', signature)

      // 调用合约前，打印所有关键参数
      console.log('permit.permitted.token', permit.permitted.token)
      console.log('permit2TokenBankContract.address', permit2TokenBankContract.address)
      console.log('permit2TokenContract.address', permit2TokenContract.address)
      console.log('msg.sender/用户地址', address)
      console.log('permit', permit)
      console.log('signature', signature)
      console.log('parsedAmount', BigInt(parsedAmount))

      // 调用测试合约函数 testPermitTransferFrom
      const hash = await walletClient.writeContract({
        account: address as `0x${string}`,
        address: permit2TokenBankContract.address as `0x${string}`,
        abi: permit2TokenBankContract.abi,
        functionName: 'testPermitTransferFrom',
        args: [permit, signature, address as `0x${string}`, BigInt(parsedAmount)]
      })
      console.log('交易 hash', hash)

      // 等待交易确认
      await publicClient.waitForTransactionReceipt({ hash })
      console.log('交易已确认')
      
      // 刷新余额
      await Promise.all([getTokenBalance(), getBankBalance()])
      console.log('余额已刷新')
    } catch (error) {
      console.error('Permit2 存款失败:', error)
      throw error
    }
  }

  // 取款
  const withdraw = async (amount: string) => {
    if (!addressRef.value) return
    isLoading.value = true
    try {
      const hash = await walletClient.writeContract({
        account: addressRef.value as `0x${string}`,
        address: permit2TokenBankContract.address as `0x${string}`,
        abi: permit2TokenBankContract.abi,
        functionName: 'userWithdraw',
        args: [parseAmount(amount)]
      })
      await publicClient.waitForTransactionReceipt({ hash })

      // 更新余额
      await Promise.all([getTokenBalance(), getBankBalance()])
    } catch (error) {
      console.error('取款失败:', error)
    } finally {
      isLoading.value = false
    }
  }

  // 使用 permit 存款
  const permitDeposit = async (amount: string) => {
    if (!addressRef.value) return
    isLoading.value = true
    try {
      const deadline = BigInt(Math.floor(Date.now() / 1000) + 3600) // 1小时后过期
      const nonce = await publicClient.readContract({
        address: permit2TokenContract.address as `0x${string}`,
        abi: permit2TokenContract.abi,
        functionName: 'nonces',
        args: [addressRef.value as `0x${string}`]
      })

      // 获取签名
      const signature = await walletClient.signTypedData({
        account: addressRef.value as `0x${string}`,
        domain: {
          name: 'zhf_erc2612permit2',
          version: '1',
          chainId: 31337n,
          verifyingContract: permit2TokenContract.address as `0x${string}`
        },
        types: {
          Permit: [
            { name: 'owner', type: 'address' },
            { name: 'spender', type: 'address' },
            { name: 'value', type: 'uint256' },
            { name: 'nonce', type: 'uint256' },
            { name: 'deadline', type: 'uint256' }
          ]
        },
        primaryType: 'Permit',
        message: {
          owner: addressRef.value as `0x${string}`,
          spender: permit2TokenBankContract.address as `0x${string}`,
          value: parseAmount(amount),
          nonce: nonce as bigint,
          deadline
        }
      }) as `0x${string}`

      // 解析签名
      const { v, r, s } = parseSignature(signature)

      // 调用 permitDeposit
      const hash = await walletClient.writeContract({
        account: addressRef.value as `0x${string}`,
        address: permit2TokenBankContract.address as `0x${string}`,
        abi: permit2TokenBankContract.abi,
        functionName: 'permitDeposit',
        args: [parseAmount(amount), deadline, v, r, s]
      })
      await publicClient.waitForTransactionReceipt({ hash })

      // 更新余额
      await Promise.all([getTokenBalance(), getBankBalance()])
    } catch (error) {
      console.error('permit 存款失败:', error)
    } finally {
      isLoading.value = false
    }
  }

  return {
    tokenBalance,
    bankBalance,
    isLoading,
    getTokenBalance,
    getBankBalance,
    deposit,
    withdraw,
    permitDeposit,
    permit2Approve,
    depositWithPermit2
  }
} 