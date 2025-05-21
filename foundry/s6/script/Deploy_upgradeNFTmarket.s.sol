// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/tokens/ERC721Upgradeable.sol";
import "../src/market/NFTMarketUpgradeable.sol";
import "../src/upgrade/upgradeProxy.sol";
import "../src/upgrade/NFTMarketUpgradeableV2.sol";

contract DeployScript is Script {
    // 网络配置
    uint256 constant SEPOLIA_CHAIN_ID = 11155111;
    
    // 合约名称
    string constant NFT_NAME = "TestNFT";
    string constant NFT_SYMBOL = "TNFT";

    function run() external {
        // 只从环境变量获取 Etherscan API Key
        string memory etherscanApiKey = vm.envString("ETHERSCAN_API_KEY");
        
        // 检查是否在 Sepolia 测试网
        require(block.chainid == SEPOLIA_CHAIN_ID, "Must be on Sepolia testnet");
        
        console2.log(unicode"=== 开始部署合约 ===");
        console2.log(unicode"网络: Sepolia");
        // 直接用 msg.sender 作为部署者地址
        console2.log(unicode"部署者地址:", msg.sender);
        
        // 用 --private-key 传递的私钥自动生效
        vm.startBroadcast();

        // 1. 部署 NFT 合约
        console2.log(unicode"\n1. 部署 NFT 合约");
        ERC721UpgradeableNFT nft = new ERC721UpgradeableNFT();
        nft.initialize(NFT_NAME, NFT_SYMBOL);
        console2.log(unicode"   - 合约地址:", address(nft));
        console2.log(unicode"   - 名称:", NFT_NAME);
        console2.log(unicode"   - 符号:", NFT_SYMBOL);

        // 2. 部署原始市场合约
        console2.log(unicode"\n2. 部署原始市场合约");
        NFTMarketUpgradeable market = new NFTMarketUpgradeable();
        market.initialize();
        console2.log(unicode"   - 合约地址:", address(market));

        // 3. 部署升级后的市场合约
        console2.log(unicode"\n3. 部署升级后的市场合约");
        NFTMarketUpgradeableV2 marketV2 = new NFTMarketUpgradeableV2();
        console2.log(unicode"   - 合约地址:", address(marketV2));

        // 4. 部署代理合约
        console2.log(unicode"\n4. 部署代理合约");
        NFTMarketUpgradeableV2 proxy = new NFTMarketUpgradeableV2();
        console2.log(unicode"   - 合约地址:", address(proxy));

        vm.stopBroadcast();

        // 输出验证命令
        console2.log(unicode"\n=== 合约验证命令 ===");
        
        // NFT 合约验证命令
        string memory nftVerifyCmd = string.concat(
            "forge verify-contract ",
            vm.toString(address(nft)),
            " src/tokens/ERC721Upgradeable.sol:ERC721UpgradeableNFT",
            " --constructor-args $(cast abi-encode \"constructor(string,string)\" \"",
            NFT_NAME,
            "\" \"",
            NFT_SYMBOL,
            "\")",
            " --chain-id ",
            vm.toString(SEPOLIA_CHAIN_ID),
            " --etherscan-api-key ",
            etherscanApiKey,
            " --watch"
        );
        console2.log(unicode"1. NFT 合约验证命令:");
        console2.log(nftVerifyCmd);

        // 原始市场合约验证命令
        string memory marketVerifyCmd = string.concat(
            "forge verify-contract ",
            vm.toString(address(market)),
            " src/market/NFTMarketUpgradeable.sol:NFTMarketUpgradeable",
            " --chain-id ",
            vm.toString(SEPOLIA_CHAIN_ID),
            " --etherscan-api-key ",
            etherscanApiKey,
            " --watch"
        );
        console2.log(unicode"\n2. 原始市场合约验证命令:");
        console2.log(marketVerifyCmd);

        // 升级后市场合约验证命令
        string memory marketV2VerifyCmd = string.concat(
            "forge verify-contract ",
            vm.toString(address(marketV2)),
            " src/upgrade/NFTMarketUpgradeableV2.sol:NFTMarketUpgradeableV2",
            " --chain-id ",
            vm.toString(SEPOLIA_CHAIN_ID),
            " --etherscan-api-key ",
            etherscanApiKey,
            " --watch"
        );
        console2.log(unicode"\n3. 升级后市场合约验证命令:");
        console2.log(marketV2VerifyCmd);

        // 代理合约验证命令
        string memory proxyVerifyCmd = string.concat(
            "forge verify-contract ",
            vm.toString(address(proxy)),
            " src/upgrade/upgradeProxy.sol:NFTMarketUpgradeableV2",
            " --chain-id ",
            vm.toString(SEPOLIA_CHAIN_ID),
            " --etherscan-api-key ",
            etherscanApiKey,
            " --watch"
        );
        console2.log(unicode"\n4. 代理合约验证命令:");
        console2.log(proxyVerifyCmd);

        console2.log(unicode"\n=== 部署完成 ===");
        console2.log(unicode"请确保已设置 ETHERSCAN_API_KEY 环境变量");
        console2.log(unicode"使用上述验证命令开源合约");
    }
} 