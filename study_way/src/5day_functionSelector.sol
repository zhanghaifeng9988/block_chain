pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT


contract FunctionSelector {
    uint256 private storedValue;

    function getValue() public view returns (uint) {
        return storedValue;
    }

    function setValue(uint value) public {
        storedValue = value;
    }

    function getFunctionSelector1() public pure returns (bytes4) {
        //
       bytes4 selector1 =bytes4(keccak256("getValue()"));
        return selector1;
    }

    function getFunctionSelector2() public pure returns (bytes4) {
        //
         bytes4 selector2 =bytes4(keccak256("setValue(uint256)"));
         return selector2;
    }
}