// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/tokens/vestingToken.sol";
import "../src/others/vesting.sol";

contract VestingTest is Test {
    VestingToken public token;
    TokenVesting public vesting;
    address public admin;
    address public beneficiary;
    uint256 public startTime;
    
    // 设置初始数据
    function setUp() public {
        // 设置管理员和受益人地址
        admin = address(1);
        beneficiary = address(2);
        
        // 部署代币合约
        vm.prank(admin);
        token = new VestingToken();
        
        // 记录开始时间
        startTime = block.timestamp;
        
        // 部署Vesting合约
        vm.prank(admin);
        vesting = new TokenVesting(
            beneficiary,
            address(token),
            uint64(startTime)
        );
        
        // 转入100万代币到Vesting合约
        vm.prank(admin);
        token.transfer(address(vesting), 1_000_000 * 10**18);
    }
    
    // 测试场景1：第11个月尝试释放（应该失败）
    function test_ReleaseBeforeCliff() public {
        // 快进到第11个月
        vm.warp(startTime + 330 days);
        
        // 尝试释放代币（应该失败）
        vm.prank(beneficiary);
        vm.expectRevert("TokenVesting: no tokens are due");
        vesting.release();
    }
    
    // 测试场景2：第13个月释放（应该成功）
    function test_ReleaseAfterCliff() public {
        // 快进到第13个月
        vm.warp(startTime + 395 days);
        
        // 记录释放前的余额
        uint256 balanceBefore = token.balanceOf(beneficiary);
        
        // 释放代币
        vm.prank(beneficiary);
        vesting.release();
        
        // 验证代币已经释放
        uint256 balanceAfter = token.balanceOf(beneficiary);
        assertTrue(balanceAfter > balanceBefore, "No tokens were released");
    }
    
    // 测试场景3：第25个月尝试释放（应该失败，因为已经全部释放）
    function test_ReleaseAfterVesting() public {
        // 快进到第25个月
        vm.warp(startTime + 750 days);
        
        // 先释放所有可用代币
        vm.prank(beneficiary);
        vesting.release();
        
        // 再次尝试释放（应该失败）
        vm.prank(beneficiary);
        vm.expectRevert("TokenVesting: no tokens are due");
        vesting.release();
    }
}