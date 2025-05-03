pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

contract ABIEncoder {
    function encodeUint(uint256 value) 
    public pure returns (bytes memory) {
        //encode
        return abi.encode(value);
    }

    function encodeMultiple(
        uint num,
        string memory text
    ) public pure returns (bytes memory) {
       //encode
       return abi.encode(num, text);
    }
}

contract ABIDecoder {
    function decodeUint(bytes memory data) 
    public pure returns (uint) {
        //decode,(uint) 是一个类型元组，指定了解码后的数据类型。所以decodedValue也是元组类型
         (uint decodedValue) = abi.decode(data, (uint));
        return decodedValue;
    }

    function decodeMultiple(
        bytes memory data
    ) public pure returns (uint, string memory) {
        //decode
         (uint num, string memory text) = abi.decode(data, (uint, string));
        return (num, text);

    }
}