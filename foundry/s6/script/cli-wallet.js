const { ethers } = require("ethers");
const readline = require("readline");

// 配置 Sepolia 网络
const SEPOLIA_RPC_URL = "https://ethereum-sepolia-rpc.publicnode.com"; // 示例：Infura/Alchemy 提供的 RPC 节点
const ERC20_CONTRACT_ADDRESS = "0xa740eE38BB16e25fd0417f57e00119eb99a05127"; // MTK合约地址（根据交易记录替换）
const ERC20_ABI = [
  "function transfer(address to, uint256 amount) external returns (bool)",
  "function balanceOf(address account) external view returns (uint256)"
];

// 初始化 provider
//是脚本连接 Sepolia 测试网的关键组件，所有与区块链网络的交互（查询、交易）都依赖它完成。
const provider = new ethers.JsonRpcProvider(SEPOLIA_RPC_URL);

// 1. 生成随机私钥和钱包地址
function generatePrivateKey() {
  const wallet = ethers.Wallet.createRandom();//生成 Sepolia 测试网的钱包（私钥+地址）
  console.log("\n=== 生成结果 ===");
  console.log("私钥（敏感！仅测试使用）:", wallet.privateKey);
  console.log("对应地址:", wallet.address);
  return wallet;
}

// 2. 查询余额（ETH 和 ERC20）
async function getBalances(address) {
  try {
    // 查询 ETH 余额（不变）
    const ethBalanceWei = await provider.getBalance(address);
    const ethBalance = ethers.formatEther(ethBalanceWei);

    // 查询 ERC20 余额（修改精度为18）
    const erc20Contract = new ethers.Contract(ERC20_CONTRACT_ADDRESS, ERC20_ABI, provider);
    const erc20BalanceWei = await erc20Contract.balanceOf(address);
    const erc20Balance = ethers.formatUnits(erc20BalanceWei, 18); // MTK精度为18（根据实际调整）

    return { eth: ethBalance, erc20: erc20Balance };
  } catch (error) {
    throw new Error(`查询余额失败: ${error.message}`); // 明确错误来源
  }
}

// 3. 构建 EIP-1559 ERC20 转账交易（若需要发送MTK，需同步调整精度）
async function buildEip1559Transaction(sender, recipient, amount) {
  try {
    const erc20Contract = new ethers.Contract(ERC20_CONTRACT_ADDRESS, ERC20_ABI, provider);
    console.log("erc20Contract 实例:", erc20Contract);
    
    // 获取链上建议的 gas 参数（EIP-1559 关键参数）
    const feeData = await provider.getFeeData();
    const nonce = await provider.getTransactionCount(sender); 

    // 适配 ethers.js v6：通过 transfer 方法的 estimateGas 属性估算 gas（关键修改）
    const gasLimit = await erc20Contract.transfer.estimateGas(
      recipient,
      ethers.parseUnits(amount, 18)
    );

    // 构建交易参数
    const tx = {
      to: ERC20_CONTRACT_ADDRESS, 
      nonce: nonce,
      maxPriorityFeePerGas: feeData.maxPriorityFeePerGas, 
      maxFeePerGas: feeData.maxFeePerGas, 
      gasLimit: gasLimit, 
      data: erc20Contract.interface.encodeFunctionData("transfer", [
        recipient,
        ethers.parseUnits(amount, 18) 
      ]),
      chainId: 11155111 
    };
    return tx;
  } catch (error) {
    throw new Error(`构建交易失败: ${error.message}`); 
  }
}

// 4. 签名并发送交易
async function signAndSendTransaction(wallet, tx) {
  // 签名交易
  const signedTx = await wallet.signTransaction(tx);
  // 发送交易
  const receipt = await provider.sendTransaction(signedTx);
  return receipt;
}

// 命令行交互主流程
async function main() {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
  });

  console.log("\n=== 命令行钱包 ===");
  console.log("功能选项：");
  console.log("1. 生成新私钥");
  console.log("2. 查询地址余额（ETH + ERC20）");
  console.log("3. 发送 ERC20 转账（EIP-1559 交易）");

  rl.question("请输入选项（1/2/3）: ", async (choice) => {
    switch (choice) {
      case "1":
        generatePrivateKey();
        rl.close();
        break;

      case "2":
        rl.question("请输入要查询的地址: ", async (address) => {
          try {
            const balances = await getBalances(address);
            console.log("\n=== 余额查询结果 ===");
            console.log(`ETH 余额: ${balances.eth} ETH`);
            console.log(`ERC20 余额: ${balances.erc20} USDC`);
          } catch (error) {
            console.error("查询失败:", error.message);
          }
          rl.close();
        });
        break;

      case "3":
        rl.question("请输入发送方私钥: ", async (privateKey) => {
          const wallet = new ethers.Wallet(privateKey, provider);
          rl.question("请输入接收方地址: ", async (recipient) => {
            rl.question("请输入转账金额（MTK）: ", async (amount) => {
              try {
                // 构建交易
                const tx = await buildEip1559Transaction(wallet.address, recipient, amount);
                // 确认发送
                rl.question("确认发送此交易？(y/n): ", async (confirm) => {
                  if (confirm.toLowerCase() === "y") {
                    const receipt = await signAndSendTransaction(wallet, tx);
                    console.log("\n=== 交易已发送 ===");
                    console.log("交易哈希:", receipt.hash);
                    console.log("查看链接: https://sepolia.etherscan.io/tx/" + receipt.hash);
                  } else {
                    console.log("交易已取消");
                  }
                  rl.close();
                });
                // 替换为以下代码（重点修改打印交易参数的 JSON.stringify）
                console.log("\n=== 待签名交易参数 ===");
                // 添加 BigInt 转字符串的 replacer 函数
                console.log(JSON.stringify(tx, (key, value) => 
                  typeof value === 'bigint' ? value.toString() : value, 2));
              } catch (error) {
                console.error("交易失败:", error.message);
                rl.close();
              }
            });
          });
        });
        break;

      default:
        console.log("无效选项");
        rl.close();
        break;
    }
  });
}

main();