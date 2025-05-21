// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "../src/tokens/ERC721Upgradeable.sol";
import "../src/market/NFTMarketUpgradeable.sol";
import "../src/upgrade/upgradeProxy.sol";
import "../src/upgrade/NFTMarketUpgradeableV2.sol";
import "../src/tokens/9day_thridToken.sol";
import "@openzeppelin-upgradeable/contracts/utils/cryptography/ECDSAUpgradeable.sol";

contract UpgradeNFTMarketTest is Test {
    using ECDSAUpgradeable for bytes32;

    ERC721UpgradeableNFT nft;
    NFTMarketUpgradeable market;
    NFTMarketUpgradeableV2 marketV2;
    ExtendERC20Two public erc20Token;
    address alice = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address bob = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
    address charlie = address(0x3);

    // 用于签名的私钥
    uint256 private alicePrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    uint256 private bobPrivateKey = 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d;

    function setUp() public {
        console2.log(unicode"=== 开始设置测试环境 ===");
        
        // 部署 NFT 合约
        console2.log(unicode"1. 部署 NFT 合约");
        nft = new ERC721UpgradeableNFT();
        nft.initialize("TestNFT", "TNFT");
        console2.log(unicode"   - NFT 合约地址:", address(nft));

        // 部署 ERC20 合约
        console2.log(unicode"2. 部署 ERC20 合约");
        erc20Token = new ExtendERC20Two(address(this));
        erc20Token.mintToDeployer();
        console2.log(unicode"   - ERC20 合约地址:", address(erc20Token));
        console2.log(unicode"   - 部署者代币余额:", erc20Token.balanceOf(address(this)));

        // 部署市场合约
        console2.log(unicode"3. 部署原始市场合约");
        market = new NFTMarketUpgradeable();
        market.initialize();
        console2.log(unicode"   - 原始市场合约地址:", address(market));

        // 部署升级后的市场合约
        console2.log(unicode"4. 部署升级后的市场合约");
        marketV2 = new NFTMarketUpgradeableV2();
        console2.log(unicode"   - 升级后市场合约地址:", address(marketV2));

        // 给测试账户一些 ETH 和代币
        console2.log(unicode"5. 设置测试账户余额");
        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);
        vm.deal(charlie, 10 ether);
        
        // 获取当前合约的代币余额
        uint256 currentBalance = erc20Token.balanceOf(address(this));
        uint256 transferAmount = currentBalance / 4; // 将余额分成4份，确保不超过余额
        
        erc20Token.transfer(alice, transferAmount);
        erc20Token.transfer(bob, transferAmount);
        erc20Token.transfer(charlie, transferAmount);
        
        console2.log(unicode"   - Alice ETH 余额:", alice.balance);
        console2.log(unicode"   - Alice 代币余额:", erc20Token.balanceOf(alice));
        console2.log(unicode"   - Bob ETH 余额:", bob.balance);
        console2.log(unicode"   - Bob 代币余额:", erc20Token.balanceOf(bob));
        console2.log(unicode"   - Charlie ETH 余额:", charlie.balance);
        console2.log(unicode"   - Charlie 代币余额:", erc20Token.balanceOf(charlie));
        
        console2.log(unicode"=== 测试环境设置完成 ===\n");
    }

    function testUpgradeNFTMarket() public {
        console2.log(unicode"=== 开始测试 NFT 市场升级流程 ===\n");
        
        // 1. 在原始合约上铸造和上架 NFT（ETH 支付）
        console2.log(unicode"1. 在原始合约上铸造和上架 NFT（ETH 支付）");
        vm.startPrank(alice);
        uint256 tokenId1 = nft.mintNFT(alice, "ipfs://test1");
        console2.log(unicode"   - Alice 铸造了 NFT，tokenId:", tokenId1);
        
        nft.approve(address(market), tokenId1);
        market.list(address(nft), tokenId1, 1 ether);
        console2.log(unicode"   - Alice 上架了 NFT，价格: 1 ETH");
        vm.stopPrank();

        // 2. 在原始合约上铸造和上架 NFT（代币支付）
        console2.log(unicode"2. 在原始合约上铸造和上架 NFT（代币支付）");
        vm.startPrank(bob);
        uint256 tokenId2 = nft.mintNFT(bob, "ipfs://test2");
        console2.log(unicode"   - Bob 铸造了 NFT，tokenId:", tokenId2);
        
        nft.approve(address(market), tokenId2);
        erc20Token.approve(address(market), 1000 * 10**18);
        market.listWithToken(address(nft), tokenId2, 100 * 10**18, address(erc20Token));
        console2.log(unicode"   - Bob 上架了 NFT，价格: 100 代币");
        vm.stopPrank();

        // 3. 验证原始合约上的上架状态
        console2.log(unicode"3. 验证原始合约上的上架状态");
        (address seller1, address nftAddress1, uint256 listedTokenId1, uint256 price1, address paymentToken1) = market.listings(address(nft), tokenId1);
        console2.log(unicode"   - NFT1 卖家地址:", seller1);
        console2.log(unicode"   - NFT1 合约地址:", nftAddress1);
        console2.log(unicode"   - NFT1 TokenId:", listedTokenId1);
        console2.log(unicode"   - NFT1 价格:", price1);
        console2.log(unicode"   - NFT1 支付代币:", paymentToken1);
        assertEq(seller1, alice, unicode"NFT1 卖家地址不匹配");
        assertEq(nftAddress1, address(nft), unicode"NFT1 合约地址不匹配");
        assertEq(listedTokenId1, tokenId1, unicode"NFT1 TokenId 不匹配");
        assertEq(price1, 1 ether, unicode"NFT1 价格不匹配");
        assertEq(paymentToken1, address(0), unicode"NFT1 支付代币不匹配");

        (address seller2, address nftAddress2, uint256 listedTokenId2, uint256 price2, address paymentToken2) = market.listings(address(nft), tokenId2);
        console2.log(unicode"   - NFT2 卖家地址:", seller2);
        console2.log(unicode"   - NFT2 合约地址:", nftAddress2);
        console2.log(unicode"   - NFT2 TokenId:", listedTokenId2);
        console2.log(unicode"   - NFT2 价格:", price2);
        console2.log(unicode"   - NFT2 支付代币:", paymentToken2);
        assertEq(seller2, bob, unicode"NFT2 卖家地址不匹配");
        assertEq(nftAddress2, address(nft), unicode"NFT2 合约地址不匹配");
        assertEq(listedTokenId2, tokenId2, unicode"NFT2 TokenId 不匹配");
        assertEq(price2, 100 * 10**18, unicode"NFT2 价格不匹配");
        assertEq(paymentToken2, address(erc20Token), unicode"NFT2 支付代币不匹配");

        // 4. 在原始合约上购买 NFT（ETH 支付）
        console2.log(unicode"4. 在原始合约上购买 NFT（ETH 支付）");
        vm.startPrank(charlie);
        market.buyNFT{value: 1 ether}(address(nft), tokenId1);
        console2.log(unicode"   - Charlie 使用 ETH 购买了 NFT1");
        console2.log(unicode"   - Charlie ETH 余额:", charlie.balance);
        vm.stopPrank();

        // 5. 在原始合约上购买 NFT（代币支付）
        console2.log(unicode"5. 在原始合约上购买 NFT（代币支付）");
        vm.startPrank(charlie);
        erc20Token.approve(address(market), 1000 * 10**18);
        market.buyNFTWithToken(address(nft), tokenId2, 100 * 10**18);
        console2.log(unicode"   - Charlie 使用代币购买了 NFT2");
        console2.log(unicode"   - Charlie 代币余额:", erc20Token.balanceOf(charlie));
        vm.stopPrank();

        // 6. 验证 NFT 所有权转移
        console2.log(unicode"6. 验证 NFT 所有权转移");
        assertEq(nft.ownerOf(tokenId1), charlie, unicode"NFT1 所有权未正确转移");
        assertEq(nft.ownerOf(tokenId2), charlie, unicode"NFT2 所有权未正确转移");
        console2.log(unicode"   - NFT1 所有权已转移到 Charlie");
        console2.log(unicode"   - NFT2 所有权已转移到 Charlie");

        // 7. 在升级后的合约上铸造和上架新的 NFT（使用签名，ETH 支付）
        console2.log(unicode"7. 在升级后的合约上铸造和上架新的 NFT（使用签名，ETH 支付）");
        vm.startPrank(alice);
        uint256 tokenId3 = nft.mintNFT(alice, "ipfs://test3");
        console2.log(unicode"   - Alice 铸造了新的 NFT，tokenId:", tokenId3);
        
        // 设置市场合约的授权
        nft.setApprovalForAll(address(marketV2), true);
        
        // 创建签名
        uint256 price3 = 2 ether;
        bytes32 messageHash = keccak256(abi.encodePacked(
            address(nft),
            tokenId3,
            price3,
            alice // 使用 alice 作为 msg.sender
        ));
        bytes32 ethSignedMessageHash = messageHash.toEthSignedMessageHash();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(alicePrivateKey, ethSignedMessageHash);
        bytes memory signature = abi.encodePacked(r, s, v);
        
        // 使用签名上架
        marketV2.listWithSignature(address(nft), tokenId3, price3, signature);
        console2.log(unicode"   - Alice 使用签名上架了 NFT，价格: 2 ETH");
        vm.stopPrank();

        // 8. 在升级后的合约上铸造和上架新的 NFT（使用签名，代币支付）
        console2.log(unicode"8. 在升级后的合约上铸造和上架新的 NFT（使用签名，代币支付）");
        vm.startPrank(bob);
        uint256 tokenId4 = nft.mintNFT(bob, "ipfs://test4");
        console2.log(unicode"   - Bob 铸造了新的 NFT，tokenId:", tokenId4);
        
        // 设置市场合约的授权
        nft.setApprovalForAll(address(marketV2), true);
        
        // 创建签名
        uint256 price4 = 200 * 10**18;
        messageHash = keccak256(abi.encodePacked(
            address(nft),
            tokenId4,
            price4,
            address(erc20Token),
            bob // 使用 bob 作为 msg.sender
        ));
        ethSignedMessageHash = messageHash.toEthSignedMessageHash();
        (v, r, s) = vm.sign(bobPrivateKey, ethSignedMessageHash);
        signature = abi.encodePacked(r, s, v);
        
        // 使用签名上架
        marketV2.listWithTokenAndSignature(address(nft), tokenId4, price4, address(erc20Token), signature);
        console2.log(unicode"   - Bob 使用签名上架了 NFT，价格: 200 代币");
        vm.stopPrank();

        // 9. 验证升级后合约的上架状态
        console2.log(unicode"9. 验证升级后合约的上架状态");
        NFTMarketUpgradeableV2.Listing memory listing3 = marketV2.getListing(address(nft), tokenId3);
        console2.log(unicode"   - NFT3 卖家地址:", listing3.seller);
        console2.log(unicode"   - NFT3 合约地址:", listing3.nftContract);
        console2.log(unicode"   - NFT3 TokenId:", listing3.tokenId);
        console2.log(unicode"   - NFT3 价格:", listing3.price);
        console2.log(unicode"   - NFT3 支付代币:", listing3.paymentToken);
        assertEq(listing3.seller, alice, unicode"NFT3 卖家地址不匹配");
        assertEq(listing3.nftContract, address(nft), unicode"NFT3 合约地址不匹配");
        assertEq(listing3.tokenId, tokenId3, unicode"NFT3 TokenId 不匹配");
        assertEq(listing3.price, price3, unicode"NFT3 价格不匹配");
        assertEq(listing3.paymentToken, address(0), unicode"NFT3 支付代币不匹配");

        NFTMarketUpgradeableV2.Listing memory listing4 = marketV2.getListing(address(nft), tokenId4);
        console2.log(unicode"   - NFT4 卖家地址:", listing4.seller);
        console2.log(unicode"   - NFT4 合约地址:", listing4.nftContract);
        console2.log(unicode"   - NFT4 TokenId:", listing4.tokenId);
        console2.log(unicode"   - NFT4 价格:", listing4.price);
        console2.log(unicode"   - NFT4 支付代币:", listing4.paymentToken);
        assertEq(listing4.seller, bob, unicode"NFT4 卖家地址不匹配");
        assertEq(listing4.nftContract, address(nft), unicode"NFT4 合约地址不匹配");
        assertEq(listing4.tokenId, tokenId4, unicode"NFT4 TokenId 不匹配");
        assertEq(listing4.price, price4, unicode"NFT4 价格不匹配");
        assertEq(listing4.paymentToken, address(erc20Token), unicode"NFT4 支付代币不匹配");

        // 10. 在升级后的合约上购买 NFT（ETH 支付）
        console2.log(unicode"10. 在升级后的合约上购买 NFT（ETH 支付）");
        vm.startPrank(charlie);
        marketV2.buyNFT{value: price3}(address(nft), tokenId3);
        console2.log(unicode"   - Charlie 使用 ETH 购买了 NFT3");
        console2.log(unicode"   - Charlie ETH 余额:", charlie.balance);
        vm.stopPrank();

        // 11. 在升级后的合约上购买 NFT（代币支付）
        console2.log(unicode"11. 在升级后的合约上购买 NFT（代币支付）");
        vm.startPrank(charlie);
        erc20Token.approve(address(marketV2), 1000 * 10**18);
        marketV2.buyNFTWithToken(address(nft), tokenId4, price4);
        console2.log(unicode"   - Charlie 使用代币购买了 NFT4");
        console2.log(unicode"   - Charlie 代币余额:", erc20Token.balanceOf(charlie));
        vm.stopPrank();

        // 12. 验证新 NFT 的所有权转移
        console2.log(unicode"12. 验证新 NFT 的所有权转移");
        assertEq(nft.ownerOf(tokenId3), charlie, unicode"NFT3 所有权未正确转移");
        assertEq(nft.ownerOf(tokenId4), charlie, unicode"NFT4 所有权未正确转移");
        console2.log(unicode"   - NFT3 所有权已转移到 Charlie");
        console2.log(unicode"   - NFT4 所有权已转移到 Charlie");

        // 13. 验证升级前后的状态一致性
        console2.log(unicode"13. 验证升级前后的状态一致性");
        console2.log(unicode"   - NFT1 所有者:", nft.ownerOf(tokenId1));
        console2.log(unicode"   - NFT2 所有者:", nft.ownerOf(tokenId2));
        console2.log(unicode"   - NFT3 所有者:", nft.ownerOf(tokenId3));
        console2.log(unicode"   - NFT4 所有者:", nft.ownerOf(tokenId4));
        console2.log(unicode"   - Alice ETH 余额:", alice.balance);
        console2.log(unicode"   - Alice 代币余额:", erc20Token.balanceOf(alice));
        console2.log(unicode"   - Bob ETH 余额:", bob.balance);
        console2.log(unicode"   - Bob 代币余额:", erc20Token.balanceOf(bob));
        console2.log(unicode"   - Charlie ETH 余额:", charlie.balance);
        console2.log(unicode"   - Charlie 代币余额:", erc20Token.balanceOf(charlie));

        console2.log(unicode"\n=== NFT 市场升级测试完成 ===");
    }
} 