// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract Permit2Token is ERC20, ERC20Permit {
    constructor() ERC20("zhf_erc2612permit2", "zhf_erc2612permit2") ERC20Permit("zhf_erc2612permit2") {
        _mint(msg.sender, 44444 * 10 ** decimals());
    }
} 