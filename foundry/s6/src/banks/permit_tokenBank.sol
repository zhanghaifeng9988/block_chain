// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../tokens/PermitToken.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";

contract PermitTokenBank {
    // 代币合约地址
    PermitToken public token;
    // 管理员地址
    address public admin;
    // 记录每个接收代币钱包用户的存款余额
    mapping(address => uint256) public balances;

    // 事件：存款
    event Deposited(address indexed user, address indexed to, uint256 amount);
    // 事件：通过permit存款
    event PermitDeposited(address indexed user, address indexed to, uint256 amount);
    // 事件：提款（管理员操作）
    event Withdrawn(address indexed admin, uint256 amount);
    // 事件：提款（用户操作）
    event UserWithdrawn(address indexed user, uint256 amount);

    constructor(address _token) {
        token = PermitToken(_token);
        admin = msg.sender;
    }

    // 标准存款函数
    function deposit(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        bool success = token.transferFrom(msg.sender, address(this), amount);
        require(success, "Transfer failed");
        balances[msg.sender] += amount;
        emit Deposited(msg.sender, address(this), amount);
    }

    // 使用permit进行存款的函数
    function permitDeposit(
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(amount > 0, "Amount must be greater than 0");
        
        // 首先执行permit操作
        token.permit(msg.sender, address(this), amount, deadline, v, r, s);
        
        // 然后执行转账
        bool success = token.transferFrom(msg.sender, address(this), amount);
        require(success, "Transfer failed");
        
        // 更新余额
        balances[msg.sender] += amount;
        
        emit PermitDeposited(msg.sender, address(this), amount);
    }

    // 用户提款函数
    function userWithdraw(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        require(balances[msg.sender] >= amount, "Insufficient balance");

        balances[msg.sender] -= amount;
        bool success = token.transfer(msg.sender, amount);
        require(success, "Transfer failed");

        emit UserWithdrawn(msg.sender, amount);
    }

    // 管理员提取所有代币
    function withdraw() external {
        require(msg.sender == admin, "Only admin can withdraw");
        uint256 totalBalance = token.balanceOf(address(this));
        require(totalBalance > 0, "No tokens to withdraw");

        bool success = token.transfer(admin, totalBalance);
        require(success, "Withdrawal failed");

        emit Withdrawn(admin, totalBalance);
    }

    // 查询合约当前持有的代币余额
    function getBankBalance() external view returns (uint256) {
        return token.balanceOf(address(this));
    }

    // 查询用户存款余额
    function getDepositRecord(address user) external view returns (uint256) {
        return balances[user];
    }
} 