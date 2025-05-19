// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/interfaces/IERC721.sol";
import "../src/interfaces/INFTMarket.sol";

contract ListNFTScript is Script {
    address constant NFT_ADDRESS = 0xF53701FF88DEaeBb83202F1e21E166f8951E093d;
    address constant MARKET_ADDRESS = 0x75cFefc86d4e1E9e9d570370776818b6639fa606;
    uint256 constant TOKEN_ID = 1;
    uint256 constant PRICE = 0.00001 ether;
    address constant SELLER = 0x44f08Ed7D8F63b345F0fc512aEcfaA4F16831643; // your wallet address

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // 1. Check NFT ownership
        IERC721 nft = IERC721(NFT_ADDRESS);
        address owner = nft.ownerOf(TOKEN_ID);
        console.log("NFT owner:", owner);
        require(owner == SELLER, "Not the owner of NFT");

        // 2. Approve to market contract
        // console.log("Approve to market...");
        // nft.setApprovalForAll(MARKET_ADDRESS, true);
        // console.log("Approve success");

        // 3. List NFT
        console.log("Start listing NFT...");
        INFTMarket market = INFTMarket(MARKET_ADDRESS);
        try market.list(NFT_ADDRESS, TOKEN_ID, PRICE) {
            console.log("List success!");
            console.log("NFT address:", NFT_ADDRESS);
            console.log("Token ID:", TOKEN_ID);
            console.log("Price:", PRICE);
        } catch Error(string memory reason) {
            console.log("List failed:", reason);
        } catch {
            console.log("List failed: unknown error");
        }

        vm.stopBroadcast();
    }
}