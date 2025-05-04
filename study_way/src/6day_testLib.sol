pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

library SafeMath {
    function add(uint256 x ,uint256 y) internal pure  returns (uint256) {
        uint256 z = x + y;
        require(z >= x , 'uint overflow');
        return z;
    }
}

contract TestLab {
    //库绑定，将 SafeMath 库的函数附加到 uint256 类型
    //绑定后，所有 uint256 类型的变量都会"继承" SafeMath 库中的函数
    using SafeMath for uint256;

    function testAdd(uint256 x,uint256 y) external pure  returns (uint256)  {
        //return SafeMath.add(x,y);
        return x.add(y);
    }
}

