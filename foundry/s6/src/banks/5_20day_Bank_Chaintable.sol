// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BankChainTable {
    // 管理员地址
    address public admin;
    
    // 用户余额映射
    mapping(address => uint256) public balances;
    
    // 链表节点结构
    struct Node {
        address user;
        uint256 amount;
        address next;  // 指向下一个节点的地址
        address prev;  // 指向前一个节点的地址
    }
    
    // 存储所有节点的映射
    mapping(address => Node) public nodes;
    
    // 头节点地址
    address public head;
    
    // 尾节点地址
    address public tail;
    
    // 当前排名中的用户数量
    uint256 public userCount;
    
    // 最大存储的排名数量
    uint256 public constant MAX_RANK = 10;
    
    // 事件
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed admin, uint256 amount);
    event AdminTransferred(address indexed previousAdmin, address indexed newAdmin);
    event TopUserUpdated(address indexed user, uint256 amount);
    
    // 管理员修饰器
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this operation");
        _;
    }
    
    constructor() {
        admin = msg.sender;
        head = address(0);
        tail = address(0);
        userCount = 0;
    }
    
    // 存款函数
    function deposit() external payable {
        require(msg.value > 0, "Deposit amount must be greater than zero");
        balances[msg.sender] += msg.value;
        _updateTopUsers(msg.sender, balances[msg.sender]);
        emit Deposit(msg.sender, msg.value);
    }
    
    // 更新前10名用户
    function _updateTopUsers(address user, uint256 amount) internal {
        // 如果用户已经在排名中，先移除它
        if (nodes[user].user == user) {
            _removeNode(user);
        }
        
        // 如果链表为空，直接添加
        if (head == address(0)) {
            nodes[user] = Node(user, amount, address(0), address(0));
            head = user;
            tail = user;
            userCount++;
            emit TopUserUpdated(user, amount);
            return;
        }
        
        // 查找插入位置
        address current = head;
        address prev = address(0);
        
        while (current != address(0) && nodes[current].amount >= amount) {
            prev = current;
            current = nodes[current].next;
        }
        
        // 如果未达到最大数量或金额大于最小值
        if (userCount < MAX_RANK || current != address(0)) {
            // 创建新节点
            nodes[user] = Node(user, amount, current, prev);
            
            // 更新链接
            if (prev == address(0)) {
                // 插入到头部
                head = user;
            } else {
                nodes[prev].next = user;
            }
            
            if (current == address(0)) {
                // 插入到尾部
                tail = user;
            } else {
                nodes[current].prev = user;
            }
            
            if (userCount < MAX_RANK) {
                userCount++;
            } else if (current == address(0)) {
                // 删除最后一个节点
                address oldTail = tail;
                tail = nodes[tail].prev;
                nodes[tail].next = address(0);
                delete nodes[oldTail];
            }
        }
        
        emit TopUserUpdated(user, amount);
    }
    
    // 从链表中移除节点
    function _removeNode(address user) internal {
        if (nodes[user].prev == address(0)) {
            head = nodes[user].next;
        } else {
            nodes[nodes[user].prev].next = nodes[user].next;
        }
        
        if (nodes[user].next == address(0)) {
            tail = nodes[user].prev;
        } else {
            nodes[nodes[user].next].prev = nodes[user].prev;
        }
        
        delete nodes[user];
        userCount--;
    }
    
    // 获取前10名用户
    function getTopUsers() external view returns (address[] memory, uint256[] memory) {
        address[] memory users = new address[](userCount);
        uint256[] memory amounts = new uint256[](userCount);
        
        address current = head;
        for (uint256 i = 0; i < userCount; i++) {
            users[i] = current;
            amounts[i] = nodes[current].amount;
            current = nodes[current].next;
        }
        
        return (users, amounts);
    }
    
    // 管理员提款函数
    function withdraw() external onlyAdmin {
        uint256 amount = address(this).balance;
        require(amount > 0, "No funds to withdraw");
        
        (bool success, ) = payable(admin).call{value: amount}("");
        require(success, "Transfer failed");
        
        emit Withdraw(admin, amount);
    }
    
    // 转移管理员权限
    function transferAdmin(address newAdmin) external onlyAdmin {
        require(newAdmin != address(0), "New admin cannot be zero address");
        address oldAdmin = admin;
        admin = newAdmin;
        emit AdminTransferred(oldAdmin, newAdmin);
    }
    
    // 获取用户余额
    function getUserBalance(address user) external view returns (uint256) {
        return balances[user];
    }
    
    // 获取合约余额
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    // 接收ETH的回调函数
    receive() external payable {
        require(msg.value > 0, "Deposit amount must be greater than zero");
        balances[msg.sender] += msg.value;
        _updateTopUsers(msg.sender, balances[msg.sender]);
        emit Deposit(msg.sender, msg.value);
    }
    
    // 处理未知函数调用的回调函数
    fallback() external payable {
        require(msg.value > 0, "Deposit amount must be greater than zero");
        balances[msg.sender] += msg.value;
        _updateTopUsers(msg.sender, balances[msg.sender]);
        emit Deposit(msg.sender, msg.value);
    }
}