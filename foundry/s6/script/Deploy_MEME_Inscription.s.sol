// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/tokens/MEME_Inscription.sol";

contract DeployScript is Script {
    function run() external {
        // 检查环境变量
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("Deploying from address:", deployer);
        console.log("Network:", block.chainid);
        
        // 开始广播交易
        vm.startBroadcast(deployerPrivateKey);

        // 部署工厂合约
        MEME_Inscription factory = new MEME_Inscription();
        
        console.log("MEME_Inscription deployed to:", address(factory));
        
        // 验证部署
        require(address(factory) != address(0), "Deployment failed");
        
        // 验证合约所有者
        require(factory.owner() == deployer, "Owner not set correctly");
        
        console.log("Deployment verified successfully");
        console.log("Owner:", factory.owner());
        
        vm.stopBroadcast();
    }
} 