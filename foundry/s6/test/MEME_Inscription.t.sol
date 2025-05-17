// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/tokens/MEME_Inscription.sol";
import "../src/tokens/MEME_Token.sol";

contract MEME_InscriptionTest is Test {
    MEME_Inscription public factory;
    address public owner;
    address public creator;
    address public buyer;

    // 添加 fallback 函数来接收 ETH
    receive() external payable {}

    function setUp() public {
        owner = address(this);
        creator = makeAddr("creator");
        buyer = makeAddr("buyer");
        
        // Deploy factory
        factory = new MEME_Inscription();
        
        // Fund accounts
        vm.deal(creator, 100 ether);
        vm.deal(buyer, 100 ether);
        vm.deal(owner, 100 ether);  // 给 owner 分配 ETH
    }

    function testDeployInscription() public {
        vm.startPrank(creator);
        
        address token = factory.deployInscription(
            "xuhai",    // symbol
            1000,       // totalSupply
            10,         // perMint
            100        // price (wei)
        );
        
        assertTrue(token != address(0), "Token not deployed");
        
        (uint256 perMint, uint256 price, address tokenCreator) = factory.memeInfos(token);
        assertEq(perMint, 10, "Wrong perMint");
        assertEq(price, 100, "Wrong price");
        assertEq(MEME_Token(token).minted(), 0, "Wrong initial minted amount");
        assertEq(tokenCreator, creator, "Wrong creator");
        
        vm.stopPrank();
    }

    function testMintInscription() public {
        // First deploy a token
        vm.startPrank(creator);
        address token = factory.deployInscription("xuhai", 1000, 10, 100);
        vm.stopPrank();

        // Record balances before minting
        uint256 creatorBalanceBefore = creator.balance;
        uint256 ownerBalanceBefore = owner.balance;
        
        // Mint tokens as buyer
        vm.startPrank(buyer);
        uint256 mintCost = 10 * 100; // perMint * price
        factory.mintInscription{value: mintCost}(token);
        
        // Check token balance
        assertEq(MEME_Token(token).balanceOf(buyer), 10, "Wrong token balance");
        
        // Check fee distribution
        uint256 platformFee = mintCost / 100; // 1%
        uint256 creatorFee = mintCost - platformFee;
        
        assertEq(creator.balance, creatorBalanceBefore + creatorFee, "Wrong creator fee");
        assertEq(owner.balance, ownerBalanceBefore + platformFee, "Wrong platform fee");
        
        vm.stopPrank();
    }

    function test_RevertWhen_MintExceedsTotalSupply() public {
        // Deploy token with small total supply
        vm.startPrank(creator);
        address token = factory.deployInscription("xuhai", 15, 10, 100);
        vm.stopPrank();

        // Try to mint twice (should fail on second mint)
        vm.startPrank(buyer);
        uint256 mintCost = 10 * 100; // perMint * price
        factory.mintInscription{value: mintCost}(token); // 第一次正常
        vm.expectRevert("Exceeds total supply");
        factory.mintInscription{value: mintCost}(token); // 第二次应revert
        vm.stopPrank();
    }

    function test_RevertWhen_InsufficientPayment() public {
        vm.startPrank(creator);
        address token = factory.deployInscription("xuhai", 1000, 10, 100);
        vm.stopPrank();

        vm.startPrank(buyer);
        vm.expectRevert("Insufficient payment");
        factory.mintInscription{value: 500}(token); // Insufficient payment (should be 1000)
        vm.stopPrank();
    }
} 