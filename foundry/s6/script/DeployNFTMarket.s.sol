// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/tokens/9day_NFTmarket.sol";
import "../src/tokens/9day_thridToken.sol";
import "../src/tokens/TestNFT.sol";

contract DeployNFTMarket is Script {
    function run() external {
        uint256 deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        address deployer = vm.addr(deployerPrivateKey);
        vm.startBroadcast(deployerPrivateKey);

        // 修正：ExtendERC20Two 构造函数仅需1个参数（假设为 owner 地址）
        ExtendERC20Two erc20Token = new ExtendERC20Two(deployer);
        
        // 修正：TestNFT 构造函数无需参数
        TestNFT testNFT = new TestNFT();

        // 假设 NFTMarket 构造函数需要 (erc20Token, testNFT) 两个参数（保持原逻辑）
        NFTMarket nftMarket = new NFTMarket(address(erc20Token), address(testNFT));

        // 为部署者铸造代币（若 mintToDeployer 无参数则无需修改）
        erc20Token.mintToDeployer();

        vm.stopBroadcast();

        console.log("ERC20 Token deployed at:", address(erc20Token));
        console.log("TestNFT deployed at:", address(testNFT));
        console.log("NFTMarket deployed at:", address(nftMarket));
    }
}