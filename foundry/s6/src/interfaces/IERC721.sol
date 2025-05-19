// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
 
interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address);
    function setApprovalForAll(address operator, bool approved) external;
} 