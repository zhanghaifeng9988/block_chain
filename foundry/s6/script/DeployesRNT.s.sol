// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/esRNT.sol";

contract DeployEsRNT is Script {
    function run() external {
        vm.startBroadcast();

        esRNT token = new esRNT();

        vm.stopBroadcast();

        console.log("esRNT deployed to:", address(token));
    }
}