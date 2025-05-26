// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.6.6;

import '../interfaces/IUniswapV2ERC20.sol';

// Uniswap V2 的ERC20代币实现，用于LP代币
contract UniswapV2ERC20 is IUniswapV2ERC20 {
    // 代币名称
    string public constant name = 'Uniswap V2';
    // 代币符号
    string public constant symbol = 'UNI-V2';
    // 代币小数位数
    uint8 public constant decimals = 18;
    // 代币总供应量
    uint  public totalSupply;
    // 用户余额映射
    mapping(address => uint) public balanceOf;
    // 授权额度映射：owner => spender => amount
    mapping(address => mapping(address => uint)) public allowance;

    // EIP-712域分隔符，用于签名验证
    bytes32 public DOMAIN_SEPARATOR;
    // EIP-2612 permit函数的类型哈希
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    // 用户nonce值映射，用于防止重放攻击
    mapping(address => uint) public nonces;

    // 构造函数：初始化EIP-712域分隔符
    constructor() public {
        uint chainId;
        // 内联汇编获取链ID
        assembly {
            chainId := chainid()
        }
        // 计算域分隔符
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name)),
                keccak256(bytes('1')),
                chainId,
                address(this)
            )
        );
    }

    // 内部铸币函数
    function _mint(address to, uint value) internal {
        // 增加总供应量
        totalSupply = totalSupply + value;
        // 增加接收者余额
        balanceOf[to] = balanceOf[to] + value;
        // 触发转账事件
        emit Transfer(address(0), to, value);
    }

    // 内部销毁函数
    function _burn(address from, uint value) internal {
        // 减少发送者余额
        balanceOf[from] = balanceOf[from] - value;
        // 减少总供应量
        totalSupply = totalSupply - value;
        // 触发转账事件
        emit Transfer(from, address(0), value);
    }

    // 内部授权函数
    function _approve(address owner, address spender, uint value) private {
        // 设置授权额度
        allowance[owner][spender] = value;
        // 触发授权事件
        emit Approval(owner, spender, value);
    }

    // 内部转账函数
    function _transfer(address from, address to, uint value) private {
        // 减少发送者余额
        balanceOf[from] = balanceOf[from] - value;
        // 增加接收者余额
        balanceOf[to] = balanceOf[to] + value;
        // 触发转账事件
        emit Transfer(from, to, value);
    }

    // 外部授权函数
    function approve(address spender, uint value) external returns (bool) {
        // 调用内部授权函数
        _approve(msg.sender, spender, value);
        return true;
    }

    // 外部转账函数
    function transfer(address to, uint value) external returns (bool) {
        // 调用内部转账函数
        _transfer(msg.sender, to, value);
        return true;
    }

    // 授权转账函数
    function transferFrom(address from, address to, uint value) external returns (bool) {
        // 如果授权额度不是最大值，则减少授权额度
        if (allowance[from][msg.sender] != uint(-1)) {
            allowance[from][msg.sender] = allowance[from][msg.sender] - value;
        }
        // 执行转账
        _transfer(from, to, value);
        return true;
    }

    // EIP-2612 permit函数，允许通过签名进行授权
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        // 检查授权是否过期
        require(deadline >= block.timestamp, 'UniswapV2: EXPIRED');
        // 计算消息摘要
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        // 恢复签名者地址并验证
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'UniswapV2: INVALID_SIGNATURE');
        // 执行授权
        _approve(owner, spender, value);
    }
}