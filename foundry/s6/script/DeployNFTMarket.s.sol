// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/tokens/9day_NFTmarket.sol";

contract DeployNFTMarket is Script {
    function run() external {
        // 开始广播交易
        vm.startBroadcast();

        // 部署NFTMarket合约
        // 使用已部署的buyNFT代币合约地址、msg.sender作为费用接收地址和签名者
        NFTMarket market = new NFTMarket(
            0x2887a24C331FDbc3D8638fFF98b7997965C085d5, // buyNFT代币合约地址
            msg.sender,                                 // 平台费用接收地址
            msg.sender                                  // 签名者地址
        );
        
        // 停止广播
        vm.stopBroadcast();

        // 打印部署信息
        console.log("NFTMarket deployed to:", address(market));
    }
}