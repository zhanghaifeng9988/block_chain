// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/tokens/9day_NFTmarket.sol";
import "../src/tokens/9day_fourthToken.sol";
import "../src/tokens/8day_firstNFT.sol";

/**
 * @title NFTMarketTest
 * @dev 测试场景说明：
 * 1. testCompleteWhitelistPurchaseFlow: 完整的白名单购买流程
 *    - 验证初始状态（NFT所有权、代币余额等）
 *    - NFT上架流程
 *    - 白名单签名创建和验证
 *    - 购买流程
 *    - 最终状态验证（所有权转移、代币支付、平台费用等）
 * 
 * 2. testPermitBuy: 基本的白名单购买测试
 *    - 验证正常的白名单购买流程
 *    - 检查NFT所有权转移
 *    - 验证代币余额变化
 * 
 * 3. testPermitBuyInvalidSignature: 无效签名测试
 *    - 使用错误的签名者创建签名
 *    - 验证购买失败
 *    - 确保系统正确拒绝无效签名
 * 
 * 4. testPermitBuyExpired: 过期签名测试
 *    - 创建过期的签名
 *    - 验证购买失败
 *    - 确保系统正确拒绝过期签名
 * 
 * Token和NFT转移流程：
 * 1. NFT转移：
 *    - 初始状态：NFT属于卖家
 *    - 上架时：NFT授权给市场合约
 *    - 购买时：NFT从卖家转移到买家
 * 
 * 2. Token转移：
 *    - 初始状态：
 *      * 卖家余额：1000 Token
 *      * 买家余额：1000 Token
 *      * 平台费用接收地址：0 Token
 *    - 购买时：
 *      * 买家支付：100 Token
 *      * 卖家收到：98 Token (100 - 2%平台费用)
 *      * 平台费用：2 Token (2%)
 *    - 最终状态：
 *      * 卖家余额：1098 Token
 *      * 买家余额：900 Token
 *      * 平台费用接收地址：2 Token
 */
contract NFTMarketTest is Test {
    NFTMarket public nftMarket;
    ExtendERC20Two public erc20Token;
    MyNFT public nft;
    
    address public owner;
    address public seller;
    address public buyer;
    address public feeRecipient;
    address public signer;
    
    uint256 public constant NFT_PRICE = 100;
    uint256 public constant INITIAL_BALANCE = 1000;
    
    // 使用固定的私钥
    uint256 private constant PRIVATE_KEY = 0xA11CE;
    
    function setUp() public {
        owner = address(this);
        seller = address(0x1);
        buyer = address(0x2);
        feeRecipient = address(0x3);
        signer = vm.addr(PRIVATE_KEY); // 使用私钥生成地址
        
        // 部署合约
        erc20Token = new ExtendERC20Two();
        nft = new MyNFT();
        nftMarket = new NFTMarket(address(erc20Token), feeRecipient, signer);
        
        // 设置初始余额
        erc20Token.transfer(seller, INITIAL_BALANCE);
        erc20Token.transfer(buyer, INITIAL_BALANCE);
        
        // 铸造NFT给卖家
        nft.mintNFT(seller, "test-uri");
        
        // 卖家授权NFT市场
        vm.prank(seller);
        nft.approve(address(nftMarket), 1);
        
        // 买家授权NFT市场使用代币
        vm.prank(buyer);
        erc20Token.approve(address(nftMarket), NFT_PRICE);
    }
    
    /**
     * @dev 测试场景1：完整的白名单购买流程
     * 测试步骤：
     * 1. 验证初始状态
     *    - NFT所有权
     *    - 各方代币余额
     *    - 平台费用接收地址
     * 
     * 2. NFT上架流程
     *    - 卖家上架NFT
     *    - 验证上架价格
     * 
     * 3. 白名单签名创建
     *    - 生成签名
     *    - 创建Permit结构
     * 
     * 4. 购买流程
     *    - 买家使用白名单购买NFT
     * 
     * 5. 最终状态验证
     *    - NFT所有权转移
     *    - 代币支付
     *    - 平台费用收取
     *    - NFT从市场下架
     * 
     * NFT转移流程：
     * 1. 初始状态：
     *    - NFT所有者：卖家地址
     *    - NFT ID：1
     * 
     * 2. 上架时：
     *    - NFT授权给市场合约
     *    - 设置NFT价格：100 Token
     * 
     * 3. 购买时：
     *    - NFT从卖家转移到买家
     *    - NFT从市场下架
     * 
     * Token转移流程：
     * 1. 初始状态：
     *    - 卖家余额：1000 Token
     *    - 买家余额：1000 Token
     *    - 平台费用接收地址：0 Token
     * 
     * 2. 购买时：
     *    - 买家支付：100 Token
     *    - 卖家收到：98 Token (100 - 2%平台费用)
     *    - 平台费用：2 Token (2%)
     * 
     * 3. 最终状态：
     *    - 卖家余额：1098 Token
     *    - 买家余额：900 Token
     *    - 平台费用接收地址：2 Token
     */
    function testCompleteWhitelistPurchaseFlow() public {
        // 1. 验证初始状态
        console.log("\n=== Initial State ===");
        console.log("NFT Information:");
        console.log("- NFT ID: 1");
        console.log("- NFT Owner:", nft.ownerOf(1));
        console.log("- NFT URI:", nft.tokenURI(1));
        
        console.log("\nToken Balances:");
        console.log("- Seller Address:", seller);
        console.log("- Seller Balance:", erc20Token.balanceOf(seller));
        console.log("- Buyer Address:", buyer);
        console.log("- Buyer Balance:", erc20Token.balanceOf(buyer));
        console.log("- Fee Recipient Address:", feeRecipient);
        console.log("- Fee Recipient Balance:", erc20Token.balanceOf(feeRecipient));
        
        // 2. 卖家上架NFT
        vm.prank(seller);
        nftMarket.list(address(nft), 1, NFT_PRICE);
        console.log("\n=== After Listing ===");
        console.log("Listing Information:");
        console.log("- NFT Price:", NFT_PRICE);
        console.log("- Seller Address:", seller);
        console.log("- Listing Time:", block.timestamp);
        
        // 3. 创建白名单签名
        uint256 deadline = block.timestamp + 1 hours;
        bytes32 messageHash = keccak256(abi.encodePacked(
            buyer,
            deadline
        ));
        bytes32 hash = keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            messageHash
        ));
        
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(PRIVATE_KEY, hash);
        
        NFTMarket.Permit memory permit = NFTMarket.Permit({
            buyer: buyer,
            deadline: deadline,
            v: v,
            r: r,
            s: s
        });
        
        console.log("\n=== Whitelist Signature Information ===");
        console.log("- Signer Address:", signer);
        console.log("- Signature Expiry:", deadline);
        console.log("- Signature Message Hash:", vm.toString(hash));
        
        // 4. 买家使用白名单购买NFT
        vm.prank(buyer);
        nftMarket.permitBuy(address(nft), 1, permit);
        
        // 5. 验证最终状态
        console.log("\n=== After Purchase ===");
        console.log("NFT Transfer Information:");
        console.log("- NFT ID: 1");
        console.log("- New Owner:", nft.ownerOf(1));
        console.log("- Transfer Time:", block.timestamp);
        
        console.log("\nToken Transfer Information:");
        uint256 platformFee = (NFT_PRICE * 2) / 100; // 2% platform fee
        uint256 sellerAmount = NFT_PRICE - platformFee;
        console.log("- Buyer Payment Amount:", NFT_PRICE);
        console.log("- Seller Receipt Amount:", sellerAmount);
        console.log("- Platform Fee:", platformFee);
        
        console.log("\nFinal Balances:");
        console.log("- Seller Balance:", erc20Token.balanceOf(seller));
        console.log("- Buyer Balance:", erc20Token.balanceOf(buyer));
        console.log("- Fee Recipient Balance:", erc20Token.balanceOf(feeRecipient));
        
        // 6. 验证所有权转移
        assertEq(nft.ownerOf(1), buyer, "NFT ownership not transferred correctly");
        
        // 7. 验证代币转移
        assertEq(erc20Token.balanceOf(seller), INITIAL_BALANCE + sellerAmount, "Seller did not receive correct token amount");
        assertEq(erc20Token.balanceOf(feeRecipient), platformFee, "Platform fee not transferred correctly");
        assertEq(erc20Token.balanceOf(buyer), INITIAL_BALANCE - NFT_PRICE, "Buyer did not pay tokens correctly");
        
        // 8. 验证NFT已从市场下架
        (address seller_, uint256 price) = nftMarket.listings(address(nft), 1);
        assertEq(seller_, address(0), "NFT not delisted from market");
        assertEq(price, 0, "NFT price not cleared");
        
        console.log("\n=== Market Status ===");
        console.log("- NFT Delisted:", seller_ == address(0) ? "Yes" : "No");
        console.log("- Current Price:", price);
    }
    
    /**
     * @dev 测试场景2：基本的白名单购买测试
     * 测试步骤：
     * 1. 卖家上架NFT
     * 2. 创建有效的白名单签名
     * 3. 买家使用白名单购买NFT
     * 4. 验证：
     *    - NFT所有权已转移给买家
     *    - 卖家收到正确的代币金额（扣除平台费用）
     *    - 平台费用正确收取
     *    - 买家余额正确扣除
     */
    function testPermitBuy() public {
        // 卖家上架NFT
        vm.prank(seller);
        nftMarket.list(address(nft), 1, NFT_PRICE);
        
        // 创建签名
        uint256 deadline = block.timestamp + 1 hours;
        bytes32 messageHash = keccak256(abi.encodePacked(
            buyer,
            deadline
        ));
        bytes32 hash = keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            messageHash
        ));
        
        // 使用固定的私钥生成签名
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(PRIVATE_KEY, hash);
        
        // 创建Permit结构
        NFTMarket.Permit memory permit = NFTMarket.Permit({
            buyer: buyer,
            deadline: deadline,
            v: v,
            r: r,
            s: s
        });
        
        // 买家使用permit购买NFT
        vm.prank(buyer);
        nftMarket.permitBuy(address(nft), 1, permit);
        
        // 验证NFT所有权已转移
        assertEq(nft.ownerOf(1), buyer);
        
        // 验证代币余额变化
        assertEq(erc20Token.balanceOf(seller), INITIAL_BALANCE + NFT_PRICE - (NFT_PRICE * 2 / 100));
        assertEq(erc20Token.balanceOf(feeRecipient), NFT_PRICE * 2 / 100);
        assertEq(erc20Token.balanceOf(buyer), INITIAL_BALANCE - NFT_PRICE);
    }
    
    /**
     * @dev 测试场景3：无效签名测试
     * 测试步骤：
     * 1. 卖家上架NFT
     * 2. 使用错误的签名者创建签名
     * 3. 尝试使用无效签名购买NFT
     * 4. 验证：
     *    - 交易被拒绝
     *    - 返回"Invalid signature"错误
     *    - NFT所有权未改变
     *    - 代币余额未改变
     */
    function testPermitBuyInvalidSignature() public {
        // 卖家上架NFT
        vm.prank(seller);
        nftMarket.list(address(nft), 1, NFT_PRICE);
        
        // 使用错误的签名者创建签名
        uint256 deadline = block.timestamp + 1 hours;
        bytes32 messageHash = keccak256(abi.encodePacked(
            buyer,
            deadline
        ));
        bytes32 hash = keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            messageHash
        ));
        
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(PRIVATE_KEY + 1, hash); // 使用不同的私钥
        
        NFTMarket.Permit memory permit = NFTMarket.Permit({
            buyer: buyer,
            deadline: deadline,
            v: v,
            r: r,
            s: s
        });
        
        // 尝试购买应该失败
        vm.prank(buyer);
        vm.expectRevert("Invalid signature");
        nftMarket.permitBuy(address(nft), 1, permit);
    }
    
    /**
     * @dev 测试场景4：过期签名测试
     * 测试步骤：
     * 1. 卖家上架NFT
     * 2. 创建签名并设置1小时过期时间
     * 3. 将时间向前移动2小时
     * 4. 尝试使用过期签名购买NFT
     * 5. 验证：
     *    - 交易被拒绝
     *    - 返回"Permit expired"错误
     *    - NFT所有权未改变
     *    - 代币余额未改变
     */
    function testPermitBuyExpired() public {
        // 卖家上架NFT
        vm.prank(seller);
        nftMarket.list(address(nft), 1, NFT_PRICE);
        
        // 设置当前时间戳
        uint256 currentTime = block.timestamp;
        vm.warp(currentTime + 2 hours); // 将时间向前移动2小时
        
        // 创建过期的签名（1小时前）
        uint256 deadline = currentTime + 1 hours;
        bytes32 messageHash = keccak256(abi.encodePacked(
            buyer,
            deadline
        ));
        bytes32 hash = keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            messageHash
        ));
        
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(PRIVATE_KEY, hash);
        
        NFTMarket.Permit memory permit = NFTMarket.Permit({
            buyer: buyer,
            deadline: deadline,
            v: v,
            r: r,
            s: s
        });
        
        // 尝试购买应该失败
        vm.prank(buyer);
        vm.expectRevert("Permit expired");
        nftMarket.permitBuy(address(nft), 1, permit);
    }
} 