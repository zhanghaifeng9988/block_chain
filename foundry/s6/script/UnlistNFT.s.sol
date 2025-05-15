// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";

interface INFTMarket {
    function unlist(address nftContract, uint256 tokenId) external;
}

contract UnlistNFTScript is Script {
    address constant NFT_CONTRACT = 0xF53701FF88DEaeBb83202F1e21E166f8951E093d;
    address constant MARKET_ADDRESS = 0x75cFefc86d4e1E9e9d570370776818b6639fa606;
    uint256 constant TOKEN_ID = 1;

    function run() external {
        vm.startBroadcast();
        INFTMarket(MARKET_ADDRESS).unlist(NFT_CONTRACT, TOKEN_ID);
        vm.stopBroadcast();
    }
}