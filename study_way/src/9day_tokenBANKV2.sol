
pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

import "./9day_secondToken.sol"; // 引入扩展的ERC20合约
import "./6day_tokenBank.sol"; //

contract TokenBankV2 is TokenBank {
    // 事件：通过transferWithCallback存款
    event DepositedWithCallback(address indexed user, uint256 amount);
    
    constructor(address _token) TokenBank(_token) {}
    
    /**
     * @dev 通过transferWithCallback存款
     * @param amount 存款金额
     */
    function depositWithCallback(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        
        // 使用transferWithCallback将代币转入合约
        bool success = ExtendERC20(address(token)).transferWithCallback(address(this), amount);
        require(success, "Transfer with callback failed");
        
        // 更新存款余额
        balances[msg.sender] += amount;
        
        emit DepositedWithCallback(msg.sender, amount);
    }
    
    /**
     * @dev 实现tokensReceived回调接口
     * @param from 代币来源地址
     * @param amount 代币数量
     */
    function tokensReceived(address from, uint256 amount) external {
        require(msg.sender == address(token), "Only token contract can call");
        require(from != address(0), "Invalid sender address");
        
        // 更新存款余额
        balances[from] += amount;
        
        emit Deposited(from, address(this), amount);
    }
}