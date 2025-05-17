// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/tokens/9day_NFTmarket.sol";
import "../src/tokens/9day_thridToken.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract MockNFT is ERC721 {
    constructor() ERC721("MockNFT", "MNFT") {}
    
    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }
}

contract UserNFTMarketTest is Test {
    NFTMarket public market;
    ExtendERC20Two public token;
    MockNFT public nft;
    
    address owner = address(1);
    address seller = address(2);
    address buyer = address(3);
    
    function setUp() public {
        vm.startPrank(owner);
        token = new ExtendERC20Two(address(owner));  // Adjust based on ExtendERC20Two's actual constructor
        nft = new MockNFT();
        // Fix: Pass a valid address instead of 100
        market = new NFTMarket(address(token), address(owner));  // Second parameter is now an address
        vm.stopPrank();
        
        // Mint tokens and NFTs for testing
        vm.startPrank(owner);
        token.transfer(seller, 10 ether);
        token.transfer(buyer, 10 ether);
        vm.stopPrank();
        nft.mint(seller, 1);
    }
    
    function testListNFT() public {
        vm.startPrank(seller);
        nft.approve(address(market), 1);
        
        // Fix 3: NFTListed event expects 4 arguments with correct types (e.g., address, uint256, uint256)
        vm.expectEmit(true, true, true, true);
        emit NFTMarket.NFTListed(seller, uint256(uint160(address(nft))), 1, 1 ether); // Convert address to uint256
        market.list(address(nft), 1, 1 ether);
        
        // Fix 4: listings struct returns 3 fields (match actual struct definition)
        (address listSeller, uint256 tokenId, uint256 price) = market.listings(address(nft), 1);
        assertEq(listSeller, seller);
        assertEq(tokenId, 1);
        assertEq(price, 1 ether);
        
        vm.startPrank(buyer);
        vm.expectRevert("Not the owner");
        market.list(address(nft), 1, 1 ether);
        vm.stopPrank();
        
        vm.startPrank(seller);
        nft.approve(address(0), 1);
        vm.expectRevert("Not approved");
        market.list(address(nft), 1, 1 ether);
        vm.stopPrank();
    }
    
    function testBuyNFT() public {
        vm.startPrank(seller);
        nft.approve(address(market), 1);
        market.list(address(nft), 1, 1 ether);
        vm.stopPrank();
        
        vm.startPrank(buyer);
        token.approve(address(market), 1 ether);
        
        // Fix 5: NFTBought event expects 4 arguments (remove extra parameter)
        vm.expectEmit(true, true, true, true);
        emit NFTMarket.NFTBought(buyer, seller, 1, 1 ether);
        market.buyNFT(address(nft), 1);
        
        assertEq(nft.ownerOf(1), buyer);
        
        vm.expectRevert("NFT not listed");
        market.buyNFT(address(nft), 1);
    }
    
    function testFuzzListAndBuy(
        uint128 price, 
        address randomBuyer
    ) public {
        vm.assume(price >= 0.01 ether && price <= 10 ether);
        vm.assume(randomBuyer != address(0) && randomBuyer != seller);
        
        vm.startPrank(seller);
        nft.mint(seller, 2);
        nft.approve(address(market), 2);
        market.list(address(nft), 2, price);
        vm.stopPrank();
        
        vm.startPrank(owner);
        token.transfer(randomBuyer, price);
        vm.stopPrank();
        
        vm.startPrank(randomBuyer);
        token.approve(address(market), price);
        market.buyNFT(address(nft), 2);
        
        assertEq(nft.ownerOf(2), randomBuyer);
    }
    
    function testMarketTokenBalance() public {
        vm.startPrank(seller);
        nft.approve(address(market), 1);
        market.list(address(nft), 1, 1 ether);
        vm.stopPrank();
        
        assertEq(token.balanceOf(address(market)), 0);
        
        vm.startPrank(buyer);
        token.approve(address(market), 1 ether);
        market.buyNFT(address(nft), 1);
        
        assertEq(token.balanceOf(address(market)), 0);
    }
}