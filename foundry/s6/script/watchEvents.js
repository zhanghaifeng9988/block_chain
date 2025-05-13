const { ethers } = require("ethers");
const fs = require("fs");

// 配置
const RPC_URL = "http://localhost:8545";
const MARKET_CONTRACT_ADDRESS = "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0"; // 你的NFTMarket地址
const ABI_PATH = "./abi/NFTMarket.json"; // ABI文件路径（根据实际调整）

// 初始化
const provider = new ethers.JsonRpcProvider(RPC_URL);
const abi = JSON.parse(fs.readFileSync(ABI_PATH, "utf-8")).abi;
const contract = new ethers.Contract(MARKET_CONTRACT_ADDRESS, abi, provider);

// 监听 NFTListed 事件
contract.on("NFTListed", (seller, nftContract, tokenId, price) => {
  console.log(`NFT上架: 卖家=${seller} NFT合约=${nftContract} TokenID=${tokenId} 价格=${price}`);
});

// 监听 NFTBought 事件
contract.on("NFTBought", (buyer, seller, nftContract, tokenId, price) => {
  console.log(`NFT购买: 买家=${buyer} 卖家=${seller} NFT合约=${nftContract} TokenID=${tokenId} 价格=${price}`);
});

console.log("开始监听事件...");