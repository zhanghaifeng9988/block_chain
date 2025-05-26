// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import "forge-std/Script.sol";
import "../src/banks/permit2_tokenBank.sol";

contract DeployPermit2TokenBank is Script {
    function run() public returns (Permit2TokenBank) {
        // 直接使用地址
        address tokenAddress = 0x5FbDB2315678afecb367f032d93F642f64180aa3;
        address permit2Address = 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512;

        // 使用指定的私钥
        uint256 deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        vm.startBroadcast(deployerPrivateKey);

        // 部署合约
        Permit2TokenBank bank = new Permit2TokenBank(tokenAddress, permit2Address);

        vm.stopBroadcast();

        // 打印部署地址
        console2.log("Permit2TokenBank deployed to:", address(bank));

        return bank;
    }
} 