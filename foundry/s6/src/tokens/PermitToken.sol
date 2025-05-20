// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
 
contract PermitToken is ERC20, ERC20Permit {
    constructor() ERC20("ERC2612_study", "zhf_erc2612") ERC20Permit("ERC2612_study") {
        _mint(msg.sender, 888 * 10 ** decimals());
    }
} 