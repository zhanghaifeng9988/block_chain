
pragma solidity 0.8.26;
// SPDX-License-Identifier: MIT

import {Script, console} from "forge-std/Script.sol";
import {MyToken} from "../src/MyToken.sol";

contract DeployMyToken is Script {
    function run() external {
        vm.startBroadcast();
        new MyToken("MyToken", "MTK");
        vm.stopBroadcast();
    }
}