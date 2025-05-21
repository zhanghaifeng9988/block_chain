// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin-upgradeable/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin-upgradeable/contracts/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin-upgradeable/contracts/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin-upgradeable/contracts/utils/cryptography/ECDSAUpgradeable.sol";

contract NFTMarketUpgradeableV2 is Initializable, ReentrancyGuardUpgradeable, OwnableUpgradeable {
    using ECDSAUpgradeable for bytes32;

    // 存储 NFT 上架信息
    mapping(address => mapping(uint256 => Listing)) public listings;
    
    // 存储已使用的签名
    mapping(bytes => bool) public usedSignatures;
    
    struct Listing {
        address seller;
        address nftContract;
        uint256 tokenId;
        uint256 price;
        address paymentToken; // 支付代币地址，address(0) 表示使用 ETH
    }

    event NFTListed(address indexed seller, address indexed nftContract, uint256 indexed tokenId, uint256 price, address paymentToken);
    event NFTSold(address indexed seller, address indexed buyer, address indexed nftContract, uint256 tokenId, uint256 price, address paymentToken);
    event NFTListingCancelled(address indexed seller, address indexed nftContract, uint256 indexed tokenId);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __ReentrancyGuard_init();
        __Ownable_init();
    }

    // 使用签名上架 NFT（支持 ETH 支付）
    function listWithSignature(
        address nftContract,
        uint256 tokenId,
        uint256 price,
        bytes memory signature
    ) external nonReentrant {
        // 验证签名
        bytes32 messageHash = keccak256(abi.encodePacked(
            nftContract,
            tokenId,
            price,
            msg.sender
        ));
        bytes32 ethSignedMessageHash = messageHash.toEthSignedMessageHash();
        
        // 验证签名者是否是 NFT 所有者
        address signer = ethSignedMessageHash.recover(signature);
        require(signer == IERC721Upgradeable(nftContract).ownerOf(tokenId), "Invalid signature");
        
        // 验证签名是否已使用
        require(!usedSignatures[signature], "Signature already used");
        usedSignatures[signature] = true;

        // 验证 NFT 是否已授权给市场合约
        require(
            IERC721Upgradeable(nftContract).isApprovedForAll(signer, address(this)),
            "Market not approved for all"
        );

        // 创建上架信息
        listings[nftContract][tokenId] = Listing({
            seller: signer,
            nftContract: nftContract,
            tokenId: tokenId,
            price: price,
            paymentToken: address(0)
        });

        // 转移 NFT 到市场合约
        IERC721Upgradeable(nftContract).transferFrom(signer, address(this), tokenId);
        
        emit NFTListed(signer, nftContract, tokenId, price, address(0));
    }

    // 使用签名上架 NFT（支持 Token 支付）
    function listWithTokenAndSignature(
        address nftContract,
        uint256 tokenId,
        uint256 price,
        address paymentToken,
        bytes memory signature
    ) external nonReentrant {
        require(paymentToken != address(0), "Invalid payment token");
        
        // 验证签名
        bytes32 messageHash = keccak256(abi.encodePacked(
            nftContract,
            tokenId,
            price,
            paymentToken,
            msg.sender
        ));
        bytes32 ethSignedMessageHash = messageHash.toEthSignedMessageHash();
        
        // 验证签名者是否是 NFT 所有者
        address signer = ethSignedMessageHash.recover(signature);
        require(signer == IERC721Upgradeable(nftContract).ownerOf(tokenId), "Invalid signature");
        
        // 验证签名是否已使用
        require(!usedSignatures[signature], "Signature already used");
        usedSignatures[signature] = true;

        // 验证 NFT 是否已授权给市场合约
        require(
            IERC721Upgradeable(nftContract).isApprovedForAll(signer, address(this)),
            "Market not approved for all"
        );

        // 创建上架信息
        listings[nftContract][tokenId] = Listing({
            seller: signer,
            nftContract: nftContract,
            tokenId: tokenId,
            price: price,
            paymentToken: paymentToken
        });

        // 转移 NFT 到市场合约
        IERC721Upgradeable(nftContract).transferFrom(signer, address(this), tokenId);
        
        emit NFTListed(signer, nftContract, tokenId, price, paymentToken);
    }

    // 使用 ETH 购买 NFT
    function buyNFT(address nftContract, uint256 tokenId) external payable nonReentrant {
        Listing memory listing = listings[nftContract][tokenId];
        require(listing.price > 0, "NFT not listed");
        require(listing.paymentToken == address(0), "Not ETH payment");
        require(msg.value >= listing.price, "Insufficient payment");

        address seller = listing.seller;
        uint256 price = listing.price;

        delete listings[nftContract][tokenId];
        IERC721Upgradeable(nftContract).transferFrom(address(this), msg.sender, tokenId);
        
        (bool success, ) = payable(seller).call{value: price}("");
        require(success, "Transfer failed");

        emit NFTSold(seller, msg.sender, nftContract, tokenId, price, address(0));
    }

    // 使用 Token 购买 NFT
    function buyNFTWithToken(
        address nftContract,
        uint256 tokenId,
        uint256 amount
    ) external nonReentrant {
        Listing memory listing = listings[nftContract][tokenId];
        require(listing.price > 0, "NFT not listed");
        require(listing.paymentToken != address(0), "Not token payment");
        require(amount >= listing.price, "Insufficient payment");

        address seller = listing.seller;
        uint256 price = listing.price;
        address paymentToken = listing.paymentToken;

        delete listings[nftContract][tokenId];
        
        // 转移 NFT
        IERC721Upgradeable(nftContract).transferFrom(address(this), msg.sender, tokenId);
        
        // 转移支付代币
        require(
            IERC20Upgradeable(paymentToken).transferFrom(msg.sender, seller, price),
            "Token transfer failed"
        );

        emit NFTSold(seller, msg.sender, nftContract, tokenId, price, paymentToken);
    }

    // 取消上架
    function cancelListing(address nftContract, uint256 tokenId) external nonReentrant {
        Listing memory listing = listings[nftContract][tokenId];
        require(listing.seller == msg.sender, "Not the seller");

        delete listings[nftContract][tokenId];
        IERC721Upgradeable(nftContract).transferFrom(address(this), msg.sender, tokenId);

        emit NFTListingCancelled(msg.sender, nftContract, tokenId);
    }

    // 获取上架信息
    function getListing(address nftContract, uint256 tokenId) external view returns (Listing memory) {
        return listings[nftContract][tokenId];
    }
} 