pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

import "./utils/checkAddress.sol";

interface IERC20Receiver {
    function tokensReceived(address sender, uint256 amount) external returns (bytes4);
}

contract ExtendERC20 {
    using AddressUtils for address; // 绑定库到 address 类型
    string public name; //代币名称
    string public symbol; //代币符号
    uint8 public decimals; //代币小数位数，通常为18位

    uint256 public totalSupply; //代币总供应量

    mapping(address => uint256) balances; //地址到余额得映射

    mapping(address => mapping(address => uint256)) allowances; //授权额度映射(owner => (spender => amount))

    // 转账事件
    event Transfer(address indexed from, address indexed to, uint256 value);
    // 授权事件
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    constructor() {
        name = "ExtendERC20";
        symbol = "EXERC20";
        decimals = 18;
        totalSupply = 100000000 * (10**uint256(decimals));
        balances[msg.sender] = totalSupply;
    }

    //  该函数用于实现账户存入取出代币数量后,结果得查询
    function balanceOf(address _owner) public view returns (uint256 balance) {
        // write your code here
        return balances[_owner];
    }

    //  该函数用于转账，通常用于钱包用户转账的场景
    function transfer(address _to, uint256 _value)
        public
        returns (bool success)
    {
        // write your code here
        require(_to != address(0), "Invalid Address"); //检查接收地址，若0，则报错并回滚交易
        require(
            balances[msg.sender] >= _value,
            "ERC20: transfer amount exceeds balance"
        ); //检查调用该函数得账户地址的余额，若不足,则报错并回滚交易
        balances[msg.sender] -= _value;
        balances[_to] += _value;

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    //  被授权人调用该函数，传入代币拥有者的地址_from,将授权额度内的金额，按需转给第三个账户地址_to
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success) {
        // write your code here
        require(_to != address(0), "Invalid Address");
        require(
            balances[_from] >= _value,
            "ERC20: transfer amount exceeds balance"
        ); //_from,身份：代币所有者（owner），即实际转出资金的地址。
        require(
            allowances[_from][msg.sender] >= _value,
            "ERC20: transfer amount exceeds allowance"
        ); //msg.sender:调用函数者，身份：被授权者（spender）,检查授权额度

        balances[_from] -= _value;
        balances[_to] += _value;
        allowances[_from][msg.sender] -= _value; // 关键：更新授权额度

        emit Transfer(_from, _to, _value);
        return true;
    }

    // transferWithCallback 转账函数 ，有hook 功能
    // Hook功能 可以理解为在某个核心操作流程中插入的“钩子”，允许在特定节点触发外部自定义逻辑。
    // 常用于扩展合约的交互性，尤其是在代币转账、状态变更等关键操作前后执行附加逻辑。
    function transferWithCallback(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0), "Invalid Address");
    require(balances[msg.sender] >= _value, "ERC20: transfer amount exceeds balance");

    balances[msg.sender] -= _value;
    balances[_to] += _value;
    emit Transfer(msg.sender, _to, _value);

    if (_to.isContract()) {// 检查接收方是否是合约（而非普通地址）
        try IERC20Receiver(_to).tokensReceived(msg.sender, _value) returns (bytes4 retval) {
            require(retval == IERC20Receiver.tokensReceived.selector, "Invalid callback");
        } catch {
            revert("ERC20: tokensReceived callback failed");
        }
    }
    return true;
}

    // 辅助函数，检查地址是否为合约

    //代币所有者调用，允许另一个地址（_spender，通常是智能合约)从代币所有者的账户中转出最多 amount的代币
    //在标准的ERC20实现中，确实允许授权（approve）额度大于授权人当前余额，这是设计上的一个重要特性。
    function approve(address _spender, uint256 _value)
        public
        returns (bool success)
    {
        // _spender 通常指代合约地址
        allowances[msg.sender][_spender] = _value; // 代币拥有者调用该函数，将自己的代币授权给_spender账户_value额度
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256 remaining)
    {
        // write your code here
        return allowances[_owner][_spender]; //返回授权额度
    }
}
