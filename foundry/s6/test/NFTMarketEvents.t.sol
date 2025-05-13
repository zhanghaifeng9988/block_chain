// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/tokens/9day_NFTmarket.sol";
import "../src/tokens/9day_thridToken.sol";

contract NFTMarketEventsTest is Test {
    NFTMarket public nftMarket;
    ExtendERC20Two public erc20Token;
    address public deployer;
    address public user1;
    address public user2;

    event NFTListed(address indexed seller, address indexed nftAddress, uint256 indexed tokenId, uint256 price);
    event NFTBought(address indexed buyer, address indexed seller, address indexed nftAddress, uint256 tokenId, uint256 price);

    function setUp() public {
        // 设置测试账户
        deployer = makeAddr("deployer");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

        // 部署合约
        vm.startPrank(deployer);
        erc20Token = new ExtendERC20Two(deployer);
        nftMarket = new NFTMarket(address(erc20Token));
        erc20Token.mintToDeployer();
        vm.stopPrank();
    }

    function test_ListenEvents() public {
        // 这个测试会一直运行，监听事件
        console.log("Start listening to NFTMarket events...");
        console.log("NFTMarket contract address:", address(nftMarket));
        console.log("ERC20 Token contract address:", address(erc20Token));
        
        // 监听 NFTListed 事件
        vm.expectEmit(true, true, true, true);
        emit NFTListed(user1, address(0x123), 1, 100);
        
        // 监听 NFTBought 事件
        vm.expectEmit(true, true, true, true);
        emit NFTBought(user2, user1, address(0x123), 1, 100);
        
        // 保持测试运行
        vm.warp(block.timestamp + 365 days);
    }
} 