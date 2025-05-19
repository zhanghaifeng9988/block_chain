// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
 
interface INFTMarket {
    function list(address nftContract, uint256 tokenId, uint256 price) external;
} 