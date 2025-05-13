// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../src/banks/9day_tokenBankV3.sol";
import "../src/tokens/9day_thridToken.sol";
import {Script, console} from "forge-std/Script.sol";

contract DeployTokenBankV3 is Script {
    function run() external {
        // Get deployer address
        address deployer = msg.sender;
        console.log("Deployer Address: ", deployer);
        
        // Start broadcasting all transactions
        vm.startBroadcast();
        
        // 1. Deploy ERC20 token contract
        ExtendERC20Two erc20Token = new ExtendERC20Two(deployer);
        console.log("ERC20 Token contract Address: %s", address(erc20Token));
        
        // 2. Deploy TokenBank contract
        ERC20TokenBank tokenBank = new ERC20TokenBank(address(erc20Token));
        console.log("TokenBank Address: %s", address(tokenBank));
        
        // 3. Mint tokens to deployer
        erc20Token.mintToDeployer();
        
        vm.stopBroadcast();
        
        // Verify deployment
        console.log("\n=== Deployment Verification ===");
        
        // Verify token contract
        require(keccak256(bytes(erc20Token.name())) == keccak256(bytes("ExtendERC20Two")), "Token name incorrect");
        require(keccak256(bytes(erc20Token.symbol())) == keccak256(bytes("EXERC20")), "Token symbol incorrect");
        require(erc20Token.decimals() == 18, "Token decimals incorrect");
        require(erc20Token.totalSupply() == 2000 * 10**18, "Token total supply incorrect");
        require(erc20Token.deployed() == true, "Token not deployed");
        require(erc20Token.initialDeployer() == deployer, "Token initial deployer incorrect");
        
        // Verify token balance
        uint256 deployerBalance = erc20Token.balanceOf(deployer);
        console.log("Deployer ERC20 token balance: %s", deployerBalance);
        require(deployerBalance == 2000 * 10**18, "Deployer balance incorrect");
        
        // Verify Bank contract
        require(address(tokenBank.token()) == address(erc20Token), "Bank token address incorrect");
        require(tokenBank.getBalance(deployer) == 0, "Initial bank balance should be 0");
        
        console.log("\n=== Deployment Successful ===");
        console.log("Token Contract Address: %s", address(erc20Token));
        console.log("Bank Contract Address: %s", address(tokenBank));
        console.log("Deployer Address: %s", deployer);
        console.log("Deployer Token Balance: %s", deployerBalance);
    }
}
