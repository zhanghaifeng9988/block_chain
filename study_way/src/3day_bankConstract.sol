pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

contract Bank {
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

    // 定义事件，激发日志，为外部工具提供监听和解析
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed admin, uint256 amount);
    event TopUserUpdated(address indexed user, uint256 amount);

    // 定义1个函数装饰器，用于限制某些函数只能由合约的管理员（admin）调用
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this operation");
        _; // 占位符，表示被修饰函数的主体代码将在这里执行。
    }

    // 构造函数，该合约被部署后执行该函数，用于初始化管理员账户地址
    constructor() {
        admin = msg.sender;
    }

    // 用户存款的业务逻辑函数，payable 表示这个函数可以接收以太币
    function deposit() external payable {
        require(msg.value > 0, "Deposit amount must be greater than zero");
        _handleDeposit(msg.sender, msg.value);
    }

    // 定义管理员操作账户金额的函数
    function withdraw() external onlyAdmin {
        uint256 amount = address(this).balance;
        require(amount > 0, "No funds to withdraw");

        // 将合约中的以太币（ETH）转账给管理员的地址
        payable(admin).transfer(amount);
    }

    // 对存款用户进行排序，将前三名推入定义的两个数组中
/*    function updateTopUsers(address user, uint256 amount) internal {
        // 如果存款金额最多的用户不足三个，直接将当前用户和他的存款金额推入对应数组
        if (topUsers.length < 3) {
            topUsers.push(user);
            topDeposits.push(amount);
        } else {
            // 将当前用户存款金额与已经存在的三个金额进行循环比对，如果大于某个旧的存在值，就替换掉
            for (uint256 i = 0; i < 3; i++) {
                if (amount > topDeposits[i]) {
                    topUsers[i] = user;
                    topDeposits[i] = amount;
                    break;
                }
            }
        }

        // 触发事件，将最新的3个金额最多的存款用户信息发布出去，并执行日志记录
        emit TopUserUpdated(user, amount);
    }
*/

    function updateTopUsers(address user, uint256 amount) internal {
    // 检查是否已经是顶级用户,如果是，更新其金额,并排序
    for (uint i = 0; i < topUsers.length; i++) {
        if (topUsers[i] == user) {
            topDeposits[i] = amount;
            _sortTopUsers();
            return;
        }
    }
    
    // 如果不足3个存款用户，直接添加，并排序
    if (topUsers.length < 3) {
        topUsers.push(user);
        topDeposits.push(amount);
        _sortTopUsers();
    } 
    // 否则，检查当前用户存款金额是否大于当前最小金额，如果是，替换最小金额，并排序
    else if (amount > topDeposits[2]) {
        topUsers[2] = user;
        topDeposits[2] = amount;
        _sortTopUsers();
    }
    // 触发事件，将最新的3个金额最多的存款用户信息发布出去，并执行日志记录
    emit TopUserUpdated(user, amount);
}

// 辅助函数，对top3进行排序
function _sortTopUsers() private {
    if (topDeposits.length > 1) {          // 需要检查，避免空数组或单元素数组
        for (uint i = 0; i < 2; i++) {    // i < 3 - 1 → i < 2
            for (uint j = 0; j < 2 - i; j++) {  // j < 3 - i - 1 → j < 2 - i
                if (topDeposits[j] < topDeposits[j+1]) {
                    // 交换金额和地址（保持不变）
                    (topDeposits[j], topDeposits[j+1]) = (topDeposits[j+1], topDeposits[j]);
                    (topUsers[j], topUsers[j+1]) = (topUsers[j+1], topUsers[j]);
                }
            }
        }
    }
}




    // 返回当前合约中存储的顶级用户及其对应的存款金额
    function getTopUsers() external view returns (address[] memory, uint256[] memory) {
        return (topUsers, topDeposits);
    }

    // 返回传入的用户（指定用户）在合约中的余额
    function getUserBalance(address user) external view returns (uint256) {
        return balances[user];
    }

    // 返回本合约当前的以太坊余额
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    // 内部函数，处理存款逻辑
    function _handleDeposit(address user, uint256 amount) internal {
        // 判断用户是不是第一次存钱，是的话，就创建用户的存款账户
        if (balances[user] == 0) {
            users.push(user);
        }

        // 设置用户余额为当前合约接收的以太币数量
        balances[user] += amount;

        // 触发 Deposit 事件
        emit Deposit(user, amount);

        // 调用 updateTopUsers 函数
        updateTopUsers(user, amount);
    }

    // receive 函数，用于处理直接向合约发送以太币的情况
    receive() external payable {
        require(msg.value > 0, "Deposit amount must be greater than zero");
        _handleDeposit(msg.sender, msg.value);
    }

    // fallback 函数，用于处理调用未知函数的情况
    fallback() external payable {
        require(msg.value > 0, "Deposit amount must be greater than zero");
        _handleDeposit(msg.sender, msg.value);
    }
}