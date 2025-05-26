// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import { Permit2 } from "permit2/src/Permit2.sol";

contract DeployPermit2 is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        Permit2 permit2 = new Permit2();
        console2.log("Permit2 deployed at:", address(permit2));
        vm.stopBroadcast();
    }
} 