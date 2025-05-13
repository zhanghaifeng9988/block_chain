// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./9day_thridToken.sol";

contract NFTMarket is IERC721Receiver, IERC20Receiver {
    struct Listing { // NFT 信息
        address seller;
        address nftAddress;
        uint256 tokenId;
        uint256 price;
    }

    mapping(address => mapping(uint256 => Listing)) public listings;
    ExtendERC20Two public erc20Token;
    
    // 发布 NFT 信息的事件
    event NFTListed( 
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price
    );
    
    // 购买 NFT 信息的事件
    event NFTBought( 
        address indexed buyer,
        address indexed seller,
        address indexed nftAddress,
        uint256 tokenId,
        uint256 price
    );
    
    // 用于初始化合约中使用的 ERC20 Token
    constructor(address _erc20Token) {
        erc20Token = ExtendERC20Two(_erc20Token);
    }
    
    // NFT上架
    function list(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _price
    ) external {
        require( // 合约地址和 tokenId 必须有效，且调用者msg.sender 必须是 NFT 的所有者
            IERC721(_nftAddress).ownerOf(_tokenId) == msg.sender,
            "Not the owner"
        );
        
        require(// 当前合约地址必须是 NFT 的授权合约，或 msg.sender 是 NFT 的所有者
            IERC721(_nftAddress).getApproved(_tokenId) == address(this) ||
            IERC721(_nftAddress).isApprovedForAll(msg.sender, address(this)),
            "Not approved"
        );
        
        require(_price > 0, "Price must be greater than 0");
        
        // 保存 NFT 上架信息,结构体类型保存
        listings[_nftAddress][_tokenId] = Listing({
            seller: msg.sender,
            nftAddress: _nftAddress,
            tokenId: _tokenId,
            price: _price
        });
        
        //发布 NFT 上架事件
        emit NFTListed(msg.sender, _nftAddress, _tokenId, _price);
    }
    

    // 购买NFT
    function buyNFT(address _nftAddress, uint256 _tokenId) external {
        Listing memory listing = listings[_nftAddress][_tokenId];
        require(listing.seller != address(0), "NFT not listed");
        
        require(
            erc20Token.transferFrom(
                msg.sender,
                listing.seller,
                listing.price
            ),
            "Token transfer failed"
        );
        
        // 转移 NFT 到购买者,购买者是调用这个函数的 msg.sender
        IERC721(_nftAddress).safeTransferFrom(
            listing.seller,
            msg.sender,
            listing.tokenId
        );
        
        // 删除上架信息
        delete listings[_nftAddress][_tokenId];
        
        // 发布 NFT 购买事件
        emit NFTBought(
            msg.sender,
            listing.seller,
            _nftAddress,
            _tokenId,
            listing.price
        );
    }
    
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
            sender,
            listing.seller,
            nftAddress,
            tokenId,
            listing.price
        );
        
        return IERC20Receiver.tokensReceived.selector;
    }
    
    // 支持接口查询
    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return interfaceId == type(IERC20Receiver).interfaceId || 
               interfaceId == type(IERC721Receiver).interfaceId;
    }
}