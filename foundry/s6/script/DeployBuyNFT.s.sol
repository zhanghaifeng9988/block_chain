// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/tokens/9day_fourthToken.sol";

contract DeployBuyNFT is Script {
    function run() external {
        // 开始广播交易
        vm.startBroadcast();

        // 部署代币合约
        ExtendERC20Two token = new ExtendERC20Two();
        
        // 停止广播
        vm.stopBroadcast();

        // 打印部署信息
        console.log("Token deployed to:", address(token));
    }
}