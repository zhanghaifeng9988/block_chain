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
        uint256 next;  // 指向下一个节点的索引
    }
    
    // 存储所有节点的数组
    Node[] public nodes;
    
    // 头节点索引
    uint256 public head;
    
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
        // 初始化头节点
        nodes.push(Node(address(0), 0, 0));
        head = 0;
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
        // 如果链表为空，直接添加
        if (nodes.length == 1) {
            nodes.push(Node(user, amount, 0));
            head = 1;
            emit TopUserUpdated(user, amount);
            return;
        }
        
        // 查找插入位置
        uint256 current = head;
        uint256 prev = 0;
        uint256 insertPos = 0;
        
        // 遍历链表找到合适的插入位置
        while (current != 0) {
            if (amount > nodes[current].amount) {
                insertPos = current;
                break;
            }
            prev = current;
            current = nodes[current].next;
        }
        
        // 如果找到插入位置
        if (insertPos != 0) {
            // 创建新节点
            nodes.push(Node(user, amount, insertPos));
            uint256 newNodeIndex = nodes.length - 1;
            
            // 如果是头节点
            if (insertPos == head) {
                head = newNodeIndex;
            } else {
                // 更新前一个节点的next
                nodes[prev].next = newNodeIndex;
            }
        } else if (nodes.length - 1 < MAX_RANK) {
            // 如果没找到插入位置且未达到最大数量，添加到末尾
            nodes.push(Node(user, amount, 0));
            nodes[prev].next = nodes.length - 1;
        }
        
        // 如果超过最大数量，删除最后一个节点
        if (nodes.length - 1 > MAX_RANK) {
            current = head;
            prev = 0;
            for (uint256 i = 0; i < MAX_RANK - 1; i++) {
                prev = current;
                current = nodes[current].next;
            }
            nodes[prev].next = 0;
        }
        
        emit TopUserUpdated(user, amount);
    }
    
    // 获取前10名用户
    function getTopUsers() external view returns (address[] memory, uint256[] memory) {
        uint256 count = 0;
        uint256 current = head;
        
        // 计算实际节点数量
        while (current != 0 && count < MAX_RANK) {
            count++;
            current = nodes[current].next;
        }
        
        address[] memory users = new address[](count);
        uint256[] memory amounts = new uint256[](count);
        
        current = head;
        for (uint256 i = 0; i < count; i++) {
            users[i] = nodes[current].user;
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