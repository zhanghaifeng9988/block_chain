// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/tokens/optimize_NFTmarket.sol";
import "../src/tokens/9day_thridToken.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract MockNFT is ERC721 {
    constructor() ERC721("MockNFT", "MNFT") {}
    
    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }
}

contract OptimizeNFTMarketTest is Test {
    NFTMarket public market;
    ExtendERC20Two public token;
    MockNFT public nft;
    
    address owner = address(1);
    address seller = address(2);
    address buyer = address(3);
    
    function setUp() public {
        vm.startPrank(owner);
        token = new ExtendERC20Two(owner);
        token.mintToDeployer();
        nft = new MockNFT();
        market = new NFTMarket(address(token), owner);
        vm.stopPrank();
        
        // Mint tokens and NFTs for testing
        // Transfer smaller amounts from owner (who received all initial supply)
        vm.startPrank(owner);
        token.transfer(seller, 10 ether);
        token.transfer(buyer, 10 ether);
        vm.stopPrank();
        nft.mint(seller, 1);
    }
    
    // Test listing NFTs
    function testListNFT() public {
        vm.startPrank(seller);
        nft.approve(address(market), 1);
        
        // Test successful listing
        vm.expectEmit(true, true, true, true);
        emit NFTMarket.NFTListed(address(nft), 1, seller, 1 ether);
        market.list(address(nft), 1, 1 ether);
        
        // Verify listing
        (address listSeller, ) = market.listings(address(nft), 1);
        assertEq(listSeller, seller);
        
        // Test listing failures
        // Not owner
        vm.startPrank(buyer);
        vm.expectRevert("Not the owner");
        market.list(address(nft), 1, 1 ether);
        vm.stopPrank();
        
        // Not approved
        vm.startPrank(seller);
        nft.approve(address(0), 1);
        vm.expectRevert("Already listed");
        market.list(address(nft), 1, 1 ether);
        vm.stopPrank();
    }
    
    // Test buying NFTs
    function testBuyNFT() public {
        // Setup listing
        vm.startPrank(seller);
        nft.approve(address(market), 1);
        market.list(address(nft), 1, 1 ether);
        vm.stopPrank();
        
        // Test successful purchase
        vm.startPrank(buyer);
        token.approve(address(market), 1 ether);
        
        vm.expectEmit(true, true, true, false);
        emit NFTMarket.NFTBought(address(nft), 1, buyer, 1 ether);
        market.buyNFT(address(nft), 1);
        
        // Verify NFT transfer
        assertEq(nft.ownerOf(1), buyer);
        
        // Test purchase failures
        // Buy own NFT
        vm.expectRevert("Not listed");
        market.buyNFT(address(nft), 1);
        
        // Rebuy same NFT
        vm.expectRevert("Not listed");
        market.buyNFT(address(nft), 1);
    }
    
    // Fuzz testing
    function testFuzzListAndBuy(
        uint128 price, 
        address randomBuyer
    ) public {
        vm.assume(price >= 0.01 ether && price <= 10 ether);
        vm.assume(randomBuyer != address(0) && randomBuyer != seller);
        
        // Setup
        vm.startPrank(seller);
        nft.mint(seller, 2);
        nft.approve(address(market), 2);
        market.list(address(nft), 2, price);
        vm.stopPrank();
        
        // Fund buyer
        vm.startPrank(owner);
        token.transfer(randomBuyer, price);
        vm.stopPrank();
        
        // Buy NFT
        vm.startPrank(randomBuyer);
        token.approve(address(market), price);
        market.buyNFT(address(nft), 2);
        
        // Verify
        assertEq(nft.ownerOf(2), randomBuyer);
    }
    
    // Invariant test: market should never hold tokens
    function testMarketTokenBalance() public {
        // Setup listing
        vm.startPrank(seller);
        nft.approve(address(market), 1);
        market.list(address(nft), 1, 1 ether);
        vm.stopPrank();
        
        // Before purchase
        assertEq(token.balanceOf(address(market)), 0);
        
        // After purchase
        vm.startPrank(buyer);
        token.approve(address(market), 1 ether);
        market.buyNFT(address(nft), 1);
        
        assertEq(token.balanceOf(address(market)), 0);
    }
} 