// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./6day_firstToken.sol";

//授权给 TokenBank合约后，它不仅能接收你批准额度的代币，
//还能在授权范围内自由操作这些代币（比如转给其他地址）

contract TokenBank {
    // 代币合约地址
    BaseERC20 public token;

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

    constructor(address _token) {
        token = BaseERC20(_token); // 传进合约地址,指向1个已部署的合约
        admin = msg.sender; // 合约部署者设为管理员
    }

    // 存入代币，代币持有者调用该函数。 如果函数不涉及原生代币，则不需要 payable。
    // 授权多少，可存入多少
    function deposit(uint256 amount) external {
        //require(amount > 0, "Amount must be greater than 0");

        // 1. 代币拥有者需要先授权（approve）TokenBank 合约可以操作其代币
        // 2. 然后调用 transferFrom 将代币转入 TokenBank
        //3.第1个参数是代币转出地址就是代币拥有者，第2个参数是代币接收地址
        bool success = token.transferFrom(msg.sender, address(this), amount);
        require(success, "Transfer failed");

        //更新代币持有者存款余额
        balances[msg.sender] += amount;

        emit Deposited(msg.sender, address(this), amount);
    }

    // 新增用户提款函数
    function userWithdraw(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        require(balances[msg.sender] >= amount, "Insufficient balance");

        // 先更新状态防止重入攻击
        balances[msg.sender] -= amount;

        bool success = token.transfer(msg.sender, amount);
        require(success, "Transfer failed");

        emit UserWithdrawn(msg.sender, amount);
    }

    // 管理员提取所有代币
    function withdraw() external {
        require(msg.sender == admin, "Only admin can withdraw");

        //查询合约代币余额
        uint256 totalBalance = token.balanceOf(address(this));
        require(totalBalance > 0, "No tokens to withdraw");

        // 将合约持有的所有代币转给管理员
        bool success = token.transfer(admin, totalBalance);
        require(success, "Withdrawal failed");

        emit Withdrawn(admin, totalBalance);
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
