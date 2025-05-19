// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/interfaces/IERC721.sol";

contract MintNFTScript is Script {
    address constant NFT_ADDRESS = 0xF53701FF88DEaeBb83202F1e21E166f8951E093d;
    address constant RECIPIENT = 0x44f08ed7d8f63b345f0fc512aecfaa4f16831643; // 你的钱包地址

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // 铸造 NFT
        IERC721 nft = IERC721(NFT_ADDRESS);
        try nft.mint(RECIPIENT, 1) {
            console.log("NFT 铸造成功！");
            console.log("接收地址:", RECIPIENT);
            console.log("Token ID: 1");
        } catch Error(string memory reason) {
            console.log("铸造失败:", reason);
        } catch {
            console.log("铸造失败: 未知错误");
        }

        vm.stopBroadcast();
    }
} 