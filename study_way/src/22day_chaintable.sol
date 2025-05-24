// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CircularLinkedList {

    // 定义链表节点的结构
    struct Node {
        address data; // 存储的地址数据
        address next; // 指向下一个节点存储的数据的地址
    }

    // 使用 mapping 存储节点信息
    // mapping key 是节点中存储的地址数据本身
    mapping(address => Node) public nodes;

    // 链表的头部，指向第一个节点存储的数据的地址
    address public head;
    // 记录链表中的节点数量
    uint256 public size;

    // 事件，用于记录节点添加
    event NodeAdded(address indexed data, address indexed nextNodeData);

    // 添加一个新节点到链表末尾
    function addNode(address _data) public {
        // 确保要添加的数据非零地址且尚未存在于链表中
        require(_data != address(0), "Data cannot be zero address");
        require(nodes[_data].data == address(0), "Data already exists");

        // 创建新节点
        nodes[_data].data = _data;

        if (head == address(0)) {
            // 如果链表为空，新节点成为头部，并指向自身形成循环
            head = _data;
            nodes[_data].next = _data;
        } else {
            // 如果链表不为空，找到当前尾部节点（其next指向head）
            address current = head;
            // 遍历找到尾部节点
            while (nodes[current].next != head) {
                current = nodes[current].next;
            }
            // 将当前尾部节点的next指向新节点
            nodes[current].next = _data;
            // 将新节点的next指向头部，完成循环
            nodes[_data].next = head;
        }

        size++;
        emit NodeAdded(_data, nodes[_data].next);
    }

    // 遍历链表并返回所有节点的数据（地址）
    function iterate() public view returns (address[] memory) {
        address[] memory result = new address[](size);
        if (size == 0) {
            return result;
        }
        address current = head;
        for (uint i = 0; i < size; i++) {
            result[i] = current;
            current = nodes[current].next;
        }

        return result;
    }

    // 获取链表大小
    function getSize() public view returns (uint256) {
        return size;
    }

    // 注意：删除节点等操作会使合约更复杂，需要仔细处理指针和mapping的更新，并且会消耗更多gas。
    // 这个示例只包含了添加和迭代的基本功能。
}
