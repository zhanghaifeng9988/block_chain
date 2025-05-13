// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20Receiver0 {
    function tokensReceived(
      address sender, 
      uint256 amount
      ) external returns (bytes4);
}


interface IERC20Receiver1 {
    function tokensReceived(
        address sender,
        uint256 amount,
        bytes calldata data
    ) external returns (bytes4);
}