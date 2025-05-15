// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";

interface INFTMarket {
    function list(address nftContract, uint256 tokenId, uint256 price) external;
}

contract ListNFTScript is Script {
    address constant NFT_CONTRACT = 0xF53701FF88DEaeBb83202F1e21E166f8951E093d;
    address constant MARKET_ADDRESS = 0x75cFefc86d4e1E9e9d570370776818b6639fa606;
    
    // 设置要上架的NFT的Token ID和价格
    uint256 constant TOKEN_ID = 1; // 替换为你要上架的NFT的Token ID
    uint256 constant PRICE = 0.00001 ether; // 设置价格为0.00001 ETH

    function run() external {
        // 从keystore获取私钥并开始广播
        vm.startBroadcast();

        // 调用市场合约的list函数上架NFT
        INFTMarket(MARKET_ADDRESS).list(NFT_CONTRACT, TOKEN_ID, PRICE);

        vm.stopBroadcast();
    }
}