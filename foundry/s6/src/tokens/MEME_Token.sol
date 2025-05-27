// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/IERC20.sol";

contract MEME_Token is IERC20 {
    string public symbol;
    uint256 public totalSupply;
    uint256 public minted;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    address public owner;
    bool public initialized;

    event MintCalled(address indexed caller, address indexed owner, address indexed to, uint256 amount);

    function initialize(string memory _symbol, uint256 _totalSupply, address _owner) external {
        require(!initialized, "Already initialized");
        symbol = _symbol;
        totalSupply = _totalSupply;
        owner = _owner;
        initialized = true;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        require(to != address(0), "Transfer to zero address");
        require(_balances[msg.sender] >= amount, "Insufficient balance");

        _balances[msg.sender] -= amount;
        _balances[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function allowance(address tokenOwner, address spender) public view override returns (uint256) {
        return _allowances[tokenOwner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        require(to != address(0), "Transfer to zero address");
        require(_balances[from] >= amount, "Insufficient balance");
        require(_allowances[from][msg.sender] >= amount, "Insufficient allowance");

        _balances[from] -= amount;
        _balances[to] += amount;
        _allowances[from][msg.sender] -= amount;
        
        emit Transfer(from, to, amount);
        return true;
    }

    function mint(address to, uint256 amount) public {
    //msg.sender 是调用 mint 函数的地址，也就是 MEME_Inscription 工厂合约的地址
    //to 是接收者地址,就是钱包地址
        emit MintCalled(msg.sender, owner, to, amount);
        require(msg.sender == owner || msg.sender == address(this), "Only owner can mint");
        require(minted + amount <= totalSupply, "Exceeds total supply");
        minted += amount;
        _balances[to] += amount;
        // 这里触发 Transfer 事件，表示代币从"无"（零地址）转移到接收者
        emit Transfer(address(0), to, amount);
    }
} 