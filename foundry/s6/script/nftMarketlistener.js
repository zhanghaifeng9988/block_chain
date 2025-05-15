const ethers = require("ethers");

// 配置信息
const MARKET_ADDRESS = "0x75cFefc86d4e1E9e9d570370776818b6639fa606";
const MARKET_ABI = [
    "event NFTListed(address indexed nftContract, uint256 indexed tokenId, address indexed seller, uint256 price)",
    "event NFTBought(address indexed nftContract, uint256 indexed tokenId, address indexed buyer, uint256 price)"
];

// 连接到Sepolia测试网
async function main() {
    // 使用HTTP Provider
    const provider = new ethers.JsonRpcProvider("https://sepolia.infura.io/v3/b2affe5792cd45bd9b462e8762d352f2");
    
    // 创建合约实例
    const marketContract = new ethers.Contract(MARKET_ADDRESS, MARKET_ABI, provider);

    console.log("开始监听NFT市场事件...");

    // 查询历史事件
    const currentBlock = await provider.getBlockNumber();
    const fromBlock = currentBlock - 1000; // 查询最近1000个区块
    
    console.log(`正在查询从区块 ${fromBlock} 到 ${currentBlock} 的历史事件...`);
    
    const listedFilter = marketContract.filters.NFTListed();
    const boughtFilter = marketContract.filters.NFTBought();
    
    const listedEvents = await marketContract.queryFilter(listedFilter, fromBlock);
    const boughtEvents = await marketContract.queryFilter(boughtFilter, fromBlock);
    
    console.log(`找到 ${listedEvents.length} 个上架事件和 ${boughtEvents.length} 个购买事件`);
    
    // 处理历史上架事件
    for (const event of listedEvents) {
        const [nftContract, tokenId, seller, price] = event.args;
        console.log("\n历史NFT上架:");
        console.log(`NFT合约地址: ${nftContract}`);
        console.log(`Token ID: ${tokenId}`);
        console.log(`卖家地址: ${seller}`);
        console.log(`价格: ${ethers.formatEther(price)} ETH`);
        console.log(`交易哈希: ${event.transactionHash}\n`);
    }
    
    // 处理历史购买事件
    for (const event of boughtEvents) {
        const [nftContract, tokenId, buyer, price] = event.args;
        console.log("\n历史NFT购买:");
        console.log(`NFT合约地址: ${nftContract}`);
        console.log(`Token ID: ${tokenId}`);
        console.log(`买家地址: ${buyer}`);
        console.log(`成交价格: ${ethers.formatEther(price)} ETH`);
        console.log(`交易哈希: ${event.transactionHash}\n`);
    }

    // 监听新区块
    provider.on("block", async (blockNumber) => {
        try {
            // 获取区块信息
            const block = await provider.getBlock(blockNumber, true);
            
            if (block && block.transactions) {
                // 遍历区块中的所有交易
                for (const tx of block.transactions) {
                    // 检查交易是否与我们的市场合约相关
                    if (tx.to && tx.to.toLowerCase() === MARKET_ADDRESS.toLowerCase()) {
                        // 获取交易收据
                        const receipt = await provider.getTransactionReceipt(tx.hash);
                        
                        if (receipt && receipt.logs) {
                            // 解析日志
                            for (const log of receipt.logs) {
                                if (log.address.toLowerCase() === MARKET_ADDRESS.toLowerCase()) {
                                    try {
                                        // 尝试解码日志
                                        const parsedLog = marketContract.interface.parseLog(log);
                                        
                                        if (parsedLog) {
                                            if (parsedLog.name === "NFTListed") {
                                                const [nftContract, tokenId, seller, price] = parsedLog.args;
                                                console.log("\n新的NFT上架:");
                                                console.log(`NFT合约地址: ${nftContract}`);
                                                console.log(`Token ID: ${tokenId}`);
                                                console.log(`卖家地址: ${seller}`);
                                                console.log(`价格: ${ethers.formatEther(price)} ETH`);
                                                console.log(`交易哈希: ${tx.hash}\n`);
                                            } else if (parsedLog.name === "NFTBought") {
                                                const [nftContract, tokenId, buyer, price] = parsedLog.args;
                                                console.log("\nNFT已售出:");
                                                console.log(`NFT合约地址: ${nftContract}`);
                                                console.log(`Token ID: ${tokenId}`);
                                                console.log(`买家地址: ${buyer}`);
                                                console.log(`成交价格: ${ethers.formatEther(price)} ETH`);
                                                console.log(`交易哈希: ${tx.hash}\n`);
                                            }
                                        }
                                    } catch (error) {
                                        // 忽略无法解析的日志
                                        continue;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        } catch (error) {
            console.error("处理区块事件时发生错误:", error);
        }
    });
}

// 运行脚本
main().catch((error) => {
    console.error("发生错误:", error);
    process.exit(1);
});