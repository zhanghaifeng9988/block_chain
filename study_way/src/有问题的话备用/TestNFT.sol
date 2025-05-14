// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "../../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract TestNFT is ERC721, Ownable {
    constructor() ERC721("TestNFT", "TNFT") {
        _transferOwnership(msg.sender);
    }

    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }
} 