// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MultipleSignatures {
    // 提案结构体
    struct Proposal {
        address to;           // 目标地址
        uint256 value;        // 转账金额
        bytes data;           // 调用数据
        bool executed;        // 是否已执行
        uint256 confirmations; // 确认数量
        mapping(address => bool) isConfirmed; // 记录每个地址是否已确认
    }

    // 状态变量
    address[] public owners;  // 多签持有者列表
    mapping(address => bool) public isOwner;  // 地址是否为多签持有者
    uint256 public required;  // 所需确认数量
    Proposal[] public proposals;  // 提案列表

    // 事件
    event ProposalSubmitted(uint256 indexed proposalId, address indexed proposer, address to, uint256 value, bytes data);
    event ProposalConfirmed(uint256 indexed proposalId, address indexed owner);
    event ProposalExecuted(uint256 indexed proposalId, address indexed executor);

    // 修饰器：仅多签持有者可调用
    modifier onlyOwner() {
        require(isOwner[msg.sender], "Not an owner");
        _;
    }

    // 修饰器：提案必须存在且未执行
    modifier proposalExists(uint256 proposalId) {
        require(proposalId < proposals.length, "Proposal does not exist");
        require(!proposals[proposalId].executed, "Proposal already executed");
        _;
    }

    // 构造函数：初始化多签持有者和所需确认数量
    constructor(address[] memory _owners) {
        require(_owners.length == 3, "Must have exactly 3 owners");
        require(_owners.length > 0, "Owners required");

        for (uint i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "Invalid owner");
            require(!isOwner[owner], "Owner not unique");
            isOwner[owner] = true;
            owners.push(owner);
        }

        // 设置所需确认数量为三分之二
        required = 2;
    }

    // 提交提案
    function submitProposal(address _to, uint256 _value, bytes memory _data) 
        public 
        onlyOwner 
        returns (uint256 proposalId) 
    {
        proposalId = proposals.length;
        Proposal storage newProposal = proposals.push();
        newProposal.to = _to;
        newProposal.value = _value;
        newProposal.data = _data;
        newProposal.executed = false;
        newProposal.confirmations = 0;

        emit ProposalSubmitted(proposalId, msg.sender, _to, _value, _data);
    }

    // 确认提案
    function confirmProposal(uint256 proposalId) 
        public 
        onlyOwner 
        proposalExists(proposalId) 
    {
        Proposal storage proposal = proposals[proposalId];
        require(!proposal.isConfirmed[msg.sender], "Already confirmed");

        proposal.isConfirmed[msg.sender] = true;
        proposal.confirmations += 1;

        emit ProposalConfirmed(proposalId, msg.sender);
    }

    // 执行提案
    function executeProposal(uint256 proposalId) 
        public 
        proposalExists(proposalId) 
    {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.confirmations >= required, "Not enough confirmations");

        proposal.executed = true;

        (bool success, ) = proposal.to.call{value: proposal.value}(proposal.data);
        require(success, "Transaction execution failed");

        emit ProposalExecuted(proposalId, msg.sender);
    }

    // 获取提案数量
    function getProposalCount() public view returns (uint256) {
        return proposals.length;
    }

    // 获取提案详情
    function getProposal(uint256 proposalId) 
        public 
        view 
        returns (
            address to,
            uint256 value,
            bytes memory data,
            bool executed,
            uint256 confirmations
        ) 
    {
        Proposal storage proposal = proposals[proposalId];
        return (
            proposal.to,
            proposal.value,
            proposal.data,
            proposal.executed,
            proposal.confirmations
        );
    }

    // 检查地址是否已确认提案
    function isConfirmed(uint256 proposalId, address owner) 
        public 
        view 
        returns (bool) 
    {
        return proposals[proposalId].isConfirmed[owner];
    }

    // 接收ETH
    receive() external payable {}
} 