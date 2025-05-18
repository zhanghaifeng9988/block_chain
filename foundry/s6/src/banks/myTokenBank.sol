// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract MyTokenBank is ReentrancyGuard {
    // 代币合约地址
    IERC20 public token;

    // 管理员地址
    address public admin;

    // 记录每个接收代币钱包用户的存款余额
    mapping(address => uint256) public balances;

    // 事件：存款
    event Deposited(address indexed user, address indexed to, uint256 amount);
    // 事件：提款（管理员操作）
    event Withdrawn(address indexed admin, uint256 amount);
    // 事件：提款（用户操作）
    event UserWithdrawn(address indexed user, uint256 amount);
    // 事件：管理员转移
    event AdminTransferred(address indexed previousAdmin, address indexed newAdmin);

    // 修饰器：只有管理员可以调用
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this operation");
        _;
    }

    constructor(address _token) {
        token = IERC20(_token); // 传进合约地址,指向已部署的 MyToken 合约
        admin = msg.sender; // 合约部署者设为管理员
    }

    // 存入代币，代币持有者调用该函数
    function deposit(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be greater than 0");

        // 1. 代币拥有者需要先授权（approve）TokenBank 合约可以操作其代币
        // 2. 然后调用 transferFrom 将代币转入 TokenBank
        bool success = token.transferFrom(msg.sender, address(this), amount);
        require(success, "Transfer failed");

        // 更新代币持有者存款余额
        balances[msg.sender] += amount;

        emit Deposited(msg.sender, address(this), amount);
    }

    // 用户提款函数
    function userWithdraw(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        require(balances[msg.sender] >= amount, "Insufficient balance");

        // 先更新状态防止重入攻击
        balances[msg.sender] -= amount;

        bool success = token.transfer(msg.sender, amount);
        require(success, "Transfer failed");

        emit UserWithdrawn(msg.sender, amount);
    }

    // 管理员提取所有代币
    function withdraw() external nonReentrant onlyAdmin {
        // 查询合约代币余额
        uint256 totalBalance = token.balanceOf(address(this));
        require(totalBalance > 0, "No tokens to withdraw");

        // 将合约持有的所有代币转给管理员
        bool success = token.transfer(admin, totalBalance);
        require(success, "Withdrawal failed");

        emit Withdrawn(admin, totalBalance);
    }

    // 转移管理员权限
    function transferAdmin(address newAdmin) external onlyAdmin {
        require(newAdmin != address(0), "New admin cannot be zero address");
        address oldAdmin = admin;
        admin = newAdmin;
        emit AdminTransferred(oldAdmin, newAdmin);
    }

    // 查询合约当前持有的代币余额
    function getBankBalance() external view returns (uint256) {
        return token.balanceOf(address(this));
    }

    // 查询每个钱包存入的token数量
    function getDepositRecord(address user) external view returns (uint256) {
        return balances[user];
    }
} 