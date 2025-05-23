// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/AutomationCompatibleInterface.sol";

contract AutomationBank is AutomationCompatibleInterface {
    // 定义地址类型的管理员
    address public admin;
    // 定义映射类型 balances，用于存储余额
    mapping(address => uint256) public balances;
    // 定义地址类型的数组，用于存款用户地址的存储
    address[] public users;
    // 定义无符号整型数组，用于存储存款量前3名用户的金额
    uint256[] public topDeposits;
    // 定义地址类型的数组，用于存储存款量前3名用户的地址
    address[] public topUsers;
    // 定义自动转账的目标地址
    address public constant AUTO_TRANSFER_ADDRESS = 0x44f08Ed7D8F63b345F0fc512aEcfaA4F16831643;
    // 定义触发自动转账的阈值
    uint256 public constant TRANSFER_THRESHOLD = 0.1 ether;
    // 定义自动转账的金额
    uint256 public constant TRANSFER_AMOUNT = 0.05 ether;
    // 标记是否需要执行自动转账
    bool public needsAutoTransfer;
    // 记录自动转账的重试次数
    uint256 public transferRetryCount;
    // 最大重试次数
    uint256 public constant MAX_RETRY_COUNT = 3;

    // 定义事件，激发日志，为外部工具提供监听和解析
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed admin, uint256 amount);
    event TopUserUpdated(address indexed user, uint256 amount);
    event AdminTransferred(address indexed previousAdmin, address indexed newAdmin);
    event AutoTransfer(address indexed from, address indexed to, uint256 amount);
    event AutoTransferNeeded(bool needed);
    event TransferRetryCountUpdated(uint256 count);

    // 定义1个函数装饰器，用于限制某些函数只能由合约的管理员（admin）调用
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this operation");
        _;
    }

    // 构造函数，该合约被部署后执行该函数，用于初始化管理员账户地址
    constructor() {
        admin = msg.sender;
    }

    // 用户存款的业务逻辑函数，payable 表示这个函数可以接收以太币
    function deposit() external payable {
        require(msg.value > 0, "Deposit amount must be greater than zero");
        _handleDeposit(msg.sender, msg.value);
        _checkAndTriggerAutoTransfer();
    }

    // 定义管理员操作账户金额的函数
    function withdraw() external onlyAdmin {
        uint256 amount = address(this).balance;
        require(amount > 0, "No funds to withdraw");

        // 使用call进行ETH转账，更安全可靠
        (bool success, ) = payable(admin).call{value: amount}("");
        require(success, "Transfer failed");
    }

    // 转移管理员权限
    function transferAdmin(address newAdmin) external onlyAdmin {
        require(newAdmin != address(0), "New admin cannot be zero address");
        address oldAdmin = admin;
        admin = newAdmin;
        emit AdminTransferred(oldAdmin, newAdmin);
    }

    // 对存款用户进行排序，将前三名推入定义的两个数组中
    function _handleDeposit(address user, uint256 amount) internal {
        balances[user] += amount;
        users.push(user);
        _updateTopUsers(user, amount);
        emit Deposit(user, amount);
    }

    // 更新前三名用户
    function _updateTopUsers(address user, uint256 amount) internal {
        // 如果用户已经在topUsers中，更新其金额
        for (uint i = 0; i < topUsers.length; i++) {
            if (topUsers[i] == user) {
                topDeposits[i] = amount;
                _sortTopUsers();
                return;
            }
        }

        // 如果topUsers未满3个，直接添加
        if (topUsers.length < 3) {
            topUsers.push(user);
            topDeposits.push(amount);
            _sortTopUsers();
            return;
        }

        // 如果新金额大于最小金额，替换最小金额
        if (amount > topDeposits[2]) {
            topUsers[2] = user;
            topDeposits[2] = amount;
            _sortTopUsers();
        }
    }

    // 对topUsers进行排序
    function _sortTopUsers() internal {
        for (uint i = 0; i < topDeposits.length - 1; i++) {
            for (uint j = 0; j < topDeposits.length - i - 1; j++) {
                if (topDeposits[j] < topDeposits[j + 1]) {
                    // 交换金额
                    uint256 tempAmount = topDeposits[j];
                    topDeposits[j] = topDeposits[j + 1];
                    topDeposits[j + 1] = tempAmount;

                    // 交换地址
                    address tempAddress = topUsers[j];
                    topUsers[j] = topUsers[j + 1];
                    topUsers[j + 1] = tempAddress;
                }
            }
        }
    }

    // 检查并触发自动转账
    function _checkAndTriggerAutoTransfer() internal {
        uint256 contractBalance = address(this).balance;
        bool needed = contractBalance >= TRANSFER_THRESHOLD;
        if (needed) {
            needsAutoTransfer = true;
            transferRetryCount = 0;  // 重置重试次数
            emit AutoTransferNeeded(true);
            emit TransferRetryCountUpdated(0);
        }
    }

    // Chainlink Automation 检查函数
    function checkUpkeep(
        bytes calldata /* checkData */
    ) external view override returns (bool upkeepNeeded, bytes memory /* performData */) {
        // 只有在需要转账且未超过最大重试次数时才返回true
        return (needsAutoTransfer && transferRetryCount < MAX_RETRY_COUNT, "");
    }

    // Chainlink Automation 执行函数
    function performUpkeep(bytes calldata /* performData */) external override {
        require(needsAutoTransfer, "No auto transfer needed");
        require(transferRetryCount < MAX_RETRY_COUNT, "Max retry count reached");
        
        uint256 contractBalance = address(this).balance;
        require(contractBalance >= TRANSFER_THRESHOLD, "Balance below threshold");
        
        // 确保有足够的余额进行转账
        require(contractBalance >= TRANSFER_AMOUNT, "Insufficient balance for transfer");
        
        (bool success, ) = payable(AUTO_TRANSFER_ADDRESS).call{value: TRANSFER_AMOUNT}("");
        
        if (success) {
            // 转账成功，重置状态
            needsAutoTransfer = false;
            transferRetryCount = 0;
            emit AutoTransfer(address(this), AUTO_TRANSFER_ADDRESS, TRANSFER_AMOUNT);
            emit AutoTransferNeeded(false);
            emit TransferRetryCountUpdated(0);
        } else {
            // 转账失败，增加重试次数
            transferRetryCount++;
            emit TransferRetryCountUpdated(transferRetryCount);
            
            // 如果达到最大重试次数，重置状态
            if (transferRetryCount >= MAX_RETRY_COUNT) {
                needsAutoTransfer = false;
                emit AutoTransferNeeded(false);
            }
        }
    }

    // 获取前三名用户
    function getTopUsers() external view returns (address[] memory, uint256[] memory) {
        return (topUsers, topDeposits);
    }

    // 获取用户余额
    function getUserBalance(address user) external view returns (uint256) {
        return balances[user];
    }

    // 获取合约余额
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    // receive 函数，用于处理直接向合约发送以太币的情况
    receive() external payable {
        require(msg.value > 0, "Deposit amount must be greater than zero");
        _handleDeposit(msg.sender, msg.value);
        _checkAndTriggerAutoTransfer();
    }

    // fallback 函数，用于处理调用未知函数的情况
    fallback() external payable {
        require(msg.value > 0, "Deposit amount must be greater than zero");
        _handleDeposit(msg.sender, msg.value);
        _checkAndTriggerAutoTransfer();
    }
} 