// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./utils/checkAddress.sol";

interface IERC20Receiver {
    function tokensReceived(
        address sender,
        uint256 amount,
        bytes calldata data
    ) external returns (bytes4);
}

contract ExtendERC20Two {
    using AddressUtils for address;
    string public name;
    string public symbol;
    uint8 public decimals;

    uint256 public totalSupply;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowances;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        name = "ExtendERC20Two";
        symbol = "EXERC20";
        decimals = 18;
        totalSupply = 100000000 * (10**uint256(decimals));
        balances[msg.sender] = totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0), "Invalid Address");
        require(balances[msg.sender] >= _value, "ERC20: transfer amount exceeds balance");
        
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success) {
        require(_to != address(0), "Invalid Address");
        require(balances[_from] >= _value, "ERC20: transfer amount exceeds balance");
        require(allowances[_from][msg.sender] >= _value, "ERC20: transfer amount exceeds allowance");

        balances[_from] -= _value;
        balances[_to] += _value;
        allowances[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    // 原始 transferWithCallback 函数
    function transferWithCallback(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0), "Invalid Address");
        require(balances[msg.sender] >= _value, "ERC20: transfer amount exceeds balance");

        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);

        if (_to.isContract()) {
            try IERC20Receiver(_to).tokensReceived(msg.sender, _value, "") returns (bytes4 retval) {
                require(retval == IERC20Receiver.tokensReceived.selector, "Invalid callback");
            } catch {
                revert("ERC20: tokensReceived callback failed");
            }
        }
        return true;
    }

    // 新增带数据的 transferWithData 函数
    function transferWithData(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) public returns (bool) {
        require(_to != address(0), "Invalid Address");
        require(balances[msg.sender] >= _value, "ERC20: transfer amount exceeds balance");

        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);

        if (_to.isContract()) {
            try IERC20Receiver(_to).tokensReceived(msg.sender, _value, _data) returns (bytes4 retval) {
                require(retval == IERC20Receiver.tokensReceived.selector, "Invalid callback");
            } catch {
                revert("ERC20: tokensReceived callback failed");
            }
        }
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowances[_owner][_spender];
    }
}