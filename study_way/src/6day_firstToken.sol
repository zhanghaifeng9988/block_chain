// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//ERC20代币  合约实现
contract BaseERC20 {
    string public name; //代币名称
    string public symbol;  //代币符号
    uint8 public decimals;  //代币小数位数，通常为18位

    uint256 public totalSupply; //代币总供应量

    mapping (address => uint256) balances; //地址到余额得映射

    mapping (address => mapping (address => uint256)) allowances; //授权额度映射(owner => (spender => amount)) 

    // 转账事件
    event Transfer(address indexed from, address indexed to, uint256 value);
    // 授权事件
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor()  {//用于初始化代币基本信息的合约构造函数
        // write your code here
        // set name,symbol,decimals,totalSupply
        name = 'BaseERC20';
        symbol = 'BERC20';
        decimals = 18;
        totalSupply= 100000000 * (10 ** uint256(decimals));
        balances[msg.sender] = totalSupply;   // 将所有初始代币分配给合约部署者
        }

    //  该函数用于实现账户余额得查询
    function balanceOf(address _owner) public view returns (uint256 balance) {
        // write your code here
        return balances[_owner];
    }

    //  该函数用于转账，通常用于钱包用户转账的场景
    function transfer(address _to, uint256 _value) public returns (bool success) {
        // write your code here
        require(_to != address(0),'Invalid Address');//检查接收地址，若0，则报错并回滚交易
        require(balances[msg.sender] >= _value,'ERC20: transfer amount exceeds balance');//检查调用该函数得账户地址的余额，若不足,则报错并回滚交易
        balances[msg.sender] -= _value;
        balances[_to] += _value;

        emit Transfer(msg.sender, _to, _value);  
        return true;   
    }

    //  被授权人调用该函数，将授权额度内的金额，按需转给第三个账户地址_to
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        // write your code here
        require(_to != address(0),'Invalid Address');
        require(balances[_from] >= _value,'ERC20: transfer amount exceeds balance');//_from,身份：代币所有者（owner），即实际转出资金的地址。
        require(allowances[_from][msg.sender] >= _value,'ERC20: transfer amount exceeds allowance');//msg.sender:调用函数者，身份：被授权者（spender）,检查授权额度
        
        balances[_from] -= _value;
        balances[_to] += _value;
        allowances[_from][msg.sender] -= _value; // 关键：更新授权额度

        emit Transfer(_from, _to, _value); 
        return true; 
    }

    
    //在标准的ERC20实现中，确实允许授权（approve）额度大于授权人当前余额，这是设计上的一个重要特性。
    function approve(address _spender, uint256 _value) public returns (bool success) {
        // write your code here
        allowances[msg.sender][_spender] = _value; // 给调用合约的账户做授权，将自己的代币授权给_spender账户_value额度
        emit Approval(msg.sender, _spender, _value); 
        return true; 
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {   
        // write your code here
       return  allowances[_owner][_spender];//返回授权额度
    }
}