// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/tokens/9day_thridToken.sol";
import "../src/banks/9day_tokenBankV3.sol";

contract TokenBankTest is Test {
    ExtendERC20Two public token;
    ERC20TokenBank public bank;
    address public deployer;
    address public user1;
    address public user2;

    function setUp() public {
        deployer = makeAddr("deployer");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

        // 部署 Token 合约
        vm.startPrank(deployer);
        token = new ExtendERC20Two(deployer);
        token.mintToDeployer();
        vm.stopPrank();

        // 部署 Bank 合约
        bank = new ERC20TokenBank(address(token));
    }

    function test_TokenDeployment() public {
        assertEq(token.name(), "ExtendERC20Two");
        assertEq(token.symbol(), "EXERC20");
        assertEq(token.decimals(), 18);
        assertEq(token.totalSupply(), 2000 * 10**18);
        assertEq(token.balanceOf(deployer), 2000 * 10**18);
    }

    function test_TokenTransfer() public {
        uint256 amount = 100 * 10**18;
        
        vm.startPrank(deployer);
        token.transfer(user1, amount);
        vm.stopPrank();

        assertEq(token.balanceOf(user1), amount);
        assertEq(token.balanceOf(deployer), 1900 * 10**18);
    }

    function test_TokenApproveAndTransferFrom() public {
        uint256 amount = 100 * 10**18;
        
        vm.startPrank(deployer);
        token.approve(user1, amount);
        vm.stopPrank();

        vm.startPrank(user1);
        token.transferFrom(deployer, user2, amount);
        vm.stopPrank();

        assertEq(token.balanceOf(user2), amount);
        assertEq(token.balanceOf(deployer), 1900 * 10**18);
    }

    function test_BankDeposit() public {
        uint256 amount = 100 * 10**18;
        
        // 先给 user1 转一些代币
        vm.startPrank(deployer);
        token.transfer(user1, amount);
        vm.stopPrank();

        // user1 存款到 Bank
        vm.startPrank(user1);
        token.approve(address(bank), amount);
        bank.deposit(amount);
        vm.stopPrank();

        assertEq(bank.getBalance(user1), amount);
        assertEq(token.balanceOf(user1), 0);
        assertEq(token.balanceOf(address(bank)), amount);
    }

    function test_BankWithdraw() public {
        uint256 amount = 100 * 10**18;
        
        // 先给 user1 转一些代币
        vm.startPrank(deployer);
        token.transfer(user1, amount);
        vm.stopPrank();

        // user1 存款到 Bank
        vm.startPrank(user1);
        token.approve(address(bank), amount);
        bank.deposit(amount);
        vm.stopPrank();

        // user1 从 Bank 取款
        vm.startPrank(user1);
        bank.withdraw(amount);
        vm.stopPrank();

        assertEq(bank.getBalance(user1), 0);
        assertEq(token.balanceOf(user1), amount);
        assertEq(token.balanceOf(address(bank)), 0);
    }

    function test_BankDepositWithData() public {
        uint256 amount = 100 * 10**18;
        
        // 先给 user1 转一些代币
        vm.startPrank(deployer);
        token.transfer(user1, amount);
        vm.stopPrank();

        // user1 使用 transferWithData 存款到 Bank
        vm.startPrank(user1);
        token.transferWithData(address(bank), amount, "");
        vm.stopPrank();

        assertEq(bank.getBalance(user1), amount);
        assertEq(token.balanceOf(user1), 0);
        assertEq(token.balanceOf(address(bank)), amount);
    }

    function testFail_BankWithdrawInsufficientBalance() public {
        uint256 amount = 100 * 10**18;
        
        // 尝试从未存款的账户取款
        vm.startPrank(user1);
        bank.withdraw(amount);
        vm.stopPrank();
    }

    function testFail_BankDepositInsufficientBalance() public {
        uint256 amount = 100 * 10**18;
        
        // 尝试用余额不足的账户存款
        vm.startPrank(user1);
        token.approve(address(bank), amount);
        bank.deposit(amount);
        vm.stopPrank();
    }

    function test_DirectTransferToBank() public {
        uint256 amount = 100 * 10**18;
        
        // 先给 user1 转一些代币
        vm.startPrank(deployer);
        token.transfer(user1, amount);
        vm.stopPrank();

        // user1 直接转账到 Bank，不需要 approve
        vm.startPrank(user1);
        token.transferWithData(address(bank), amount, "");
        vm.stopPrank();

        assertEq(bank.getBalance(user1), amount);
        assertEq(token.balanceOf(user1), 0);
        assertEq(token.balanceOf(address(bank)), amount);
    }

    function testFail_DirectTransferToBankInsufficientBalance() public {
        uint256 amount = 100 * 10**18;
        
        // 尝试用余额不足的账户直接转账到 Bank
        vm.startPrank(user1);
        token.transferWithData(address(bank), amount, "");
        vm.stopPrank();
    }
} 