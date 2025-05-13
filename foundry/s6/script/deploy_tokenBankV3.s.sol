// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../src/banks/9day_tokenBankV3.sol";
import "../src/tokens/9day_thridToken.sol";
import {Script, console} from "forge-std/Script.sol";

contract DeployTokenBankV3 is Script {
    function run() external {
        // 获取部署者地址
        address deployer = msg.sender;
         // 打印部署者地址
        console.log("Deployer Address: ", deployer);
        
        
        // 1. 先部署ERC20代币合约，传入部署者地址
        ExtendERC20Two erc20Token = new ExtendERC20Two(deployer);
        console.log("ERC20 Token contract Address: %s", address(erc20Token));
       console.log(" this test contract address: ", address(this));
       console.log("deployer ERC20 token balance: %s", erc20Token.balanceOf(deployer));
       console.log("this test contract ERC20 token balance: %s", erc20Token.balanceOf(address(this)));

        // 2. 部署TokenBankV3合约，传入ERC20代币合约地址
        ERC20TokenBank tokenBank = new ERC20TokenBank(address(erc20Token));
        console.log("TokenBank Address: %s", address(tokenBank));
        // 验证部署
        require(
            address(tokenBank.token()) == address(erc20Token),
            "TokenBankV3 deployment failed: incorrect token address"
        );

        // 3. 调用mintToDeployer将代币分配给部署者
        vm.startBroadcast();
        erc20Token.mintToDeployer();
        vm.stopBroadcast();
        console.log("Deployer ERC20 token balance: %s", erc20Token.balanceOf(deployer));
        
    }
}
