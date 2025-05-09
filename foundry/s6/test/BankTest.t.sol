// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Bank.sol";

contract BankTest is Test {
    Bank public bank;
    address public admin = address(1);
    address public user1 = address(2);
    address public user2 = address(3);
    address public user3 = address(4);
    address public user4 = address(5);

    function setUp() public {
        // 给管理员和测试用户分配初始ETH
        vm.deal(admin, 100 ether);
        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);
        vm.deal(user3, 100 ether);
        vm.deal(user4, 100 ether);
        
        vm.prank(admin);
        bank = new Bank();
    }

    // 测试存款金额更新是否正确
    function testDepositUpdatesBalance() public {
        uint256 depositAmount = 1 ether;
        
        // 记录存款前余额
        uint256 prevBalance = bank.getUserBalance(user1);
        uint256 prevContractBalance = bank.getContractBalance();

        // 用户1存款
        vm.prank(user1);
        bank.deposit{value: depositAmount}();

        // 验证存款后余额
        assertEq(bank.getUserBalance(user1), prevBalance + depositAmount, "User balance should increase by deposit amount");
        assertEq(bank.getContractBalance(), prevContractBalance + depositAmount, "Contract balance should increase by deposit amount");
    }

    // 测试只有管理员可以取款
    function testOnlyAdminCanWithdraw() public {
        // 用户1存款
        vm.prank(user1);
        bank.deposit{value: 1 ether}();

        // 非管理员尝试取款 - 应该失败
        vm.prank(user2);
        vm.expectRevert("Only admin can perform this operation");
        bank.withdraw();

        // 管理员取款 - 应该成功
        uint256 contractBalance = bank.getContractBalance();
        vm.prank(admin);
        bank.withdraw();

        // 验证合约余额清零
        assertEq(bank.getContractBalance(), 0, "Contract balance should be zero after withdrawal");
    }

    // 测试存款排名 - 1个用户
    function testTopUsersSingleUser() public {
        vm.prank(user1);
        bank.deposit{value: 1 ether}();

        (address[] memory topUsers, uint256[] memory topDeposits) = bank.getTopUsers();
        
        assertEq(topUsers.length, 1, "Should have 1 top user");
        assertEq(topUsers[0], user1, "User1 should be the top user");
        assertEq(topDeposits[0], 1 ether, "Deposit amount should match");
    }

    // 测试存款排名 - 2个用户
    function testTopUsersTwoUsers() public {
        vm.prank(user1);
        bank.deposit{value: 2 ether}();

        vm.prank(user2);
        bank.deposit{value: 1 ether}();

        (address[] memory topUsers, uint256[] memory topDeposits) = bank.getTopUsers();
        
        assertEq(topUsers.length, 2, "Should have 2 top users");
        assertEq(topUsers[0], user1, "User1 should be first");
        assertEq(topDeposits[0], 2 ether, "First deposit should be 2 ether");
        assertEq(topUsers[1], user2, "User2 should be second");
        assertEq(topDeposits[1], 1 ether, "Second deposit should be 1 ether");
    }

    // 测试存款排名 - 3个用户
    function testTopUsersThreeUsers() public {
        vm.prank(user1);
        bank.deposit{value: 3 ether}();

        vm.prank(user2);
        bank.deposit{value: 2 ether}();

        vm.prank(user3);
        bank.deposit{value: 1 ether}();

        (address[] memory topUsers, uint256[] memory topDeposits) = bank.getTopUsers();
        
        assertEq(topUsers.length, 3, "Should have 3 top users");
        assertEq(topUsers[0], user1, "User1 should be first");
        assertEq(topDeposits[0], 3 ether, "First deposit should be 3 ether");
        assertEq(topUsers[1], user2, "User2 should be second");
        assertEq(topDeposits[1], 2 ether, "Second deposit should be 2 ether");
        assertEq(topUsers[2], user3, "User3 should be third");
        assertEq(topDeposits[2], 1 ether, "Third deposit should be 1 ether");
    }

    // 测试存款排名 - 4个用户(只保留前3名)
    function testTopUsersFourUsers() public {
        vm.prank(user1);
        bank.deposit{value: 4 ether}();

        vm.prank(user2);
        bank.deposit{value: 3 ether}();

        vm.prank(user3);
        bank.deposit{value: 2 ether}();

        vm.prank(user4);
        bank.deposit{value: 1 ether}();

        (address[] memory topUsers, uint256[] memory topDeposits) = bank.getTopUsers();
        
        assertEq(topUsers.length, 3, "Should have 3 top users");
        assertEq(topUsers[0], user1, "User1 should be first");
        assertEq(topDeposits[0], 4 ether, "First deposit should be 4 ether");
        assertEq(topUsers[1], user2, "User2 should be second");
        assertEq(topDeposits[1], 3 ether, "Second deposit should be 3 ether");
        assertEq(topUsers[2], user3, "User3 should be third");
        assertEq(topDeposits[2], 2 ether, "Third deposit should be 2 ether");
    }

    // 测试同一用户多次存款
    function testSameUserMultipleDeposits() public {
        // 第一次存款
        vm.prank(user1);
        bank.deposit{value: 1 ether}();

        // 第二次存款
        vm.prank(user1);
        bank.deposit{value: 2 ether}();

        (address[] memory topUsers, uint256[] memory topDeposits) = bank.getTopUsers();
        
        assertEq(topUsers.length, 1, "Should have 1 top user");
        assertEq(topUsers[0], user1, "User1 should be the top user");
        assertEq(topDeposits[0], 3 ether, "Total deposit should be 3 ether");
        assertEq(bank.getUserBalance(user1), 3 ether, "User balance should be 3 ether");
    }
}