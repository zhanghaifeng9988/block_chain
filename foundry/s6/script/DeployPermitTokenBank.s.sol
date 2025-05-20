// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/banks/permit_tokenBank.sol";

contract DeployPermitTokenBank is Script {
    function setUp() public {}

    function run() public {
        address token = 0x5FbDB2315678afecb367f032d93F642f64180aa3;
        vm.startBroadcast();
        PermitTokenBank bank = new PermitTokenBank(token);
        console.log("PermitTokenBank deployed at:", address(bank));
        vm.stopBroadcast();
    }
} 