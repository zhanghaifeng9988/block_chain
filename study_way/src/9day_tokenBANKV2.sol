
pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

import "./9day_secondToken.sol"; // 引入扩展的ERC20合约
import "./6day_tokenBank.sol"; //

contract TokenBankV2 is TokenBank, IERC20Receiver{
    // 事件：通过transferWithCallback存款
    event DepositedWithCallback(address indexed user, uint256 amount);
    
    constructor(address _token) TokenBank(_token) {}

/*     function depositWithCallback(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        require(ExtendERC20(address(token)).transferWithCallback(address(this), amount, "Transfer failed");
        // emit DepositedWithCallback(msg.sender, amount); // 仅触发事件，余额在回调中更新
    } */
    

 function tokensReceived(address from, uint256 amount) external override returns (bytes4) {
        require(msg.sender == address(token), "Only token contract can call");
        balances[from] += amount;
        emit Deposited(from, address(this), amount);
        return this.tokensReceived.selector; // 返回函数选择器
    }
}