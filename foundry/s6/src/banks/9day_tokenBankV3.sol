// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../tokens/9day_thridToken.sol";
import "../interfaces/IERC20Receiver.sol";
import "../security/ReentrancyGuard.sol";

contract ERC20TokenBank is ReentrancyGuard, IERC20Receiver1 {
    ExtendERC20Two public token;
    mapping(address => uint256) public balances;
    
    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    
    constructor(address _token) {
        token = ExtendERC20Two(_token);
    }
    
    // 存款函数(直接调用)
    function deposit(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        balances[msg.sender] += amount;
        emit Deposited(msg.sender, amount);
    }
    
    // 存款函数(通过回调)
    function tokensReceived(
        address sender,
        uint256 amount,
        bytes calldata
    ) external override nonReentrant returns (bytes4) {
        require(msg.sender == address(token), "Only token contract can call");
        balances[sender] += amount;
        emit Deposited(sender, amount);
        return this.tokensReceived.selector;
    }
    
    // 取款函数
    function withdraw(uint256 amount) external nonReentrant {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        require(token.transfer(msg.sender, amount), "Transfer failed");
        emit Withdrawn(msg.sender, amount);
    }
    
    // 查询余额
    function getBalance(address user) external view returns (uint256) {
        return balances[user];
    }
}
