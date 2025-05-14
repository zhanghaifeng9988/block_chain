// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract ApproveNFTScript is Script {
    address constant NFT_CONTRACT = 0xF53701FF88DEaeBb83202F1e21E166f8951E093d;
    address constant MARKET_ADDRESS = 0x75cFefc86d4e1E9e9d570370776818b6639fa606;

    function run() external {
        // 从keystore获取私钥并开始广播
        vm.startBroadcast();

        // 调用setApprovalForAll授权市场合约
        IERC721(NFT_CONTRACT).setApprovalForAll(MARKET_ADDRESS, true);

        vm.stopBroadcast();
    }
}