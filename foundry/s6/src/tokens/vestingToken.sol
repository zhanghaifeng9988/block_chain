// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract VestingToken is ERC20 {
    constructor() ERC20("HF_Vesting", "HF_VST") {
        // 铸造200万代币，考虑18位小数
        _mint(msg.sender, 2_000_000 * 10**decimals());
    }
}