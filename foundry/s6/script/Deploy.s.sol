// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/tokens/PermitToken.sol";
import "../src/banks/permit_tokenBank.sol";
import "../src/3day_bankConstract.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // 部署 PermitToken
        PermitToken permitToken = new PermitToken();
        console.log("PermitToken deployed to:", address(permitToken));

        // 部署 PermitTokenBank
        PermitTokenBank permitTokenBank = new PermitTokenBank(address(permitToken));
        console.log("PermitTokenBank deployed to:", address(permitTokenBank));

        // 部署基础 Bank
        Bank bank = new Bank();
        console.log("Bank deployed to:", address(bank));

        vm.stopBroadcast();
    }
} 