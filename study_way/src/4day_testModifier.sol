pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT


contract testModifier {
    address public owner;
    uint256 public  deposited;

    constructor() {
        owner=msg.sender;
        deposited=200; // 初始值 200 wei（需合约部署时存入 ETH）
    }

    modifier onlyOwner() {
        require(msg.sender == owner,'not owner stop immediatly');
        _;
    }

    function deposit() public payable {
        deposited+=msg.value;
    }

    function withDraw(uint256 extraQuantity) public onlyOwner {
        require(extraQuantity<= deposited,'Insufficient balance');
        //将以太币从智能合约转账给 owner 地址
        deposited -= extraQuantity;
        payable(owner).transfer(extraQuantity);

/* 将 owner 地址转换为可接收 ETH 的 payable 地址（普通地址无法直接接收 ETH）。

.transfer(extraQuantity)

将合约中存储的 extraQuantity 数量的 ETH（单位：wei）转账给 owner。

如果转账失败（如 gas 不足或对方是恶意合约），会自动回滚交易（revert）。 */
    }
}

