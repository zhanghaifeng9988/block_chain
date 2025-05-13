// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "../../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";
import "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../../lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import "../tokens/9day_thridToken.sol";
import "../interfaces/IERC20Receiver.sol";

contract NFTMarket is Ownable, ReentrancyGuard, IERC721Receiver, IERC20Receiver1 {
    struct Listing {
        address seller;
        uint256 price;
        bool isActive;
    }

    // NFT合约地址 => tokenId => 上架信息
    mapping(address => mapping(uint256 => Listing)) public listings;
    
    // 平台费用比例（百分比）
    uint256 public platformFeePercentage = 2;
    
    // 平台费用接收地址
    address public feeRecipient;
    
    // ERC20代币合约
    ExtendERC20Two public erc20Token;

    event NFTListed(address indexed nftContract, uint256 indexed tokenId, address indexed seller, uint256 price);
    event NFTBought(address indexed nftContract, uint256 indexed tokenId, address indexed buyer, uint256 price);
    event NFTUnlisted(address indexed nftContract, uint256 indexed tokenId, address indexed seller);
    event PlatformFeeUpdated(uint256 newFeePercentage);
    event FeeRecipientUpdated(address newFeeRecipient);

    constructor(address _erc20Token, address _feeRecipient) {
        erc20Token = ExtendERC20Two(_erc20Token);
        feeRecipient = _feeRecipient;
        _transferOwnership(msg.sender);
    }

    // 上架NFT
    function list(address nftContract, uint256 tokenId, uint256 price) external nonReentrant {
        require(price > 0, "Price must be greater than 0");
        require(IERC721(nftContract).ownerOf(tokenId) == msg.sender, "Not the owner");
        
        // 检查是否已经上架
        require(!listings[nftContract][tokenId].isActive, "Already listed");
        
        // 记录上架信息
        listings[nftContract][tokenId] = Listing({
            seller: msg.sender,
            price: price,
            isActive: true
        });
        
        emit NFTListed(nftContract, tokenId, msg.sender, price);
    }

    // 购买NFT
    function buyNFT(address nftContract, uint256 tokenId) external nonReentrant {
        Listing storage listing = listings[nftContract][tokenId];
        require(listing.isActive, "Not listed");
        require(msg.sender != listing.seller, "Cannot buy your own NFT");
        
        // 计算平台费用
        uint256 platformFee = (listing.price * platformFeePercentage) / 100;
        uint256 sellerAmount = listing.price - platformFee;
        
        // 转移ERC20代币
        require(erc20Token.transferFrom(msg.sender, listing.seller, sellerAmount), "Transfer to seller failed");
        require(erc20Token.transferFrom(msg.sender, feeRecipient, platformFee), "Transfer fee failed");
        
        // 转移NFT
        IERC721(nftContract).transferFrom(listing.seller, msg.sender, tokenId);
        
        // 更新上架状态
        listing.isActive = false;
        
        emit NFTBought(nftContract, tokenId, msg.sender, listing.price);
    }

    // 下架NFT
    function unlist(address nftContract, uint256 tokenId) external nonReentrant {
        Listing storage listing = listings[nftContract][tokenId];
        require(listing.isActive, "Not listed");
        require(listing.seller == msg.sender, "Not the seller");
        
        listing.isActive = false;
        
        emit NFTUnlisted(nftContract, tokenId, msg.sender);
    }

    // 更新平台费用比例（仅限管理员）
    function updatePlatformFee(uint256 newFeePercentage) external onlyOwner {
        require(newFeePercentage <= 10, "Fee too high");
        platformFeePercentage = newFeePercentage;
        emit PlatformFeeUpdated(newFeePercentage);
    }

    // 更新费用接收地址（仅限管理员）
    function updateFeeRecipient(address newFeeRecipient) external onlyOwner {
        require(newFeeRecipient != address(0), "Invalid address");
        feeRecipient = newFeeRecipient;
        emit FeeRecipientUpdated(newFeeRecipient);
    }

    //转入NFT给这个合约时候的回调处理机制
    // ERC721 接收回调
    function onERC721Received(
        address, // 执行本次 NFT 转账操作的实际发起者地址
        address, // 转出地址 本次转账的 原始所有者地址（NFT转出方）
        uint256, // NFT TOKENID 
        bytes calldata  //附加信息
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector; // 必须实现这个接口，返回当前函数 4 字节的 selector
    }
    
    // ERC20 Token 接收回调（带数据）
    function tokensReceived(
        address sender,
        uint256 amount,
        bytes calldata data
    ) external override returns (bytes4) {
        require(msg.sender == address(erc20Token), "Only accept payments in the specified ERC20 token");
        
        // 解码数据，获取 NFT 地址和 tokenId
        (address nftAddress, uint256 tokenId) = abi.decode(data, (address, uint256));
        
        Listing memory listing = listings[nftAddress][tokenId];
        require(listing.seller != address(0), "NFT not listed");
        require(amount >= listing.price, "Insufficient payment");
        
        // 如果支付金额超过价格，将多余部分退回
        if (amount > listing.price) {
            require(
                erc20Token.transfer(sender, amount - listing.price),
                "Refund failed"
            );
        }
        
        // 转移 NFT
        IERC721(nftAddress).safeTransferFrom(listing.seller, sender, tokenId);
        
        // 删除上架信息
        delete listings[nftAddress][tokenId];
        
        emit NFTBought(
            nftAddress,
            tokenId,
            sender,
            listing.price
        );
        
        return IERC20Receiver1.tokensReceived.selector;
     }
    
    // 支持接口查询
    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return interfaceId == type(IERC20Receiver1).interfaceId || 
               interfaceId == type(IERC721Receiver).interfaceId;
    }
}