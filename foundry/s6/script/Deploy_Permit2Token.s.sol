// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import "forge-std/Script.sol";
import "../src/tokens/Permit2Token.sol";

contract DeployPermit2Token is Script {
    function run() public returns (Permit2Token) {
        // 使用指定的私钥
        uint256 deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        vm.startBroadcast(deployerPrivateKey);

        // 部署合约
        Permit2Token token = new Permit2Token();

        vm.stopBroadcast();

        // 打印部署地址
        console2.log("Permit2Token deployed to:", address(token));

        return token;
    }
} 