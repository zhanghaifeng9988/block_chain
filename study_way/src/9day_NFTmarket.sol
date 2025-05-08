// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./9day_thridToken.sol";

contract NFTMarket is IERC721Receiver, IERC20Receiver {
    struct Listing {
        address seller;
        address nftAddress;
        uint256 tokenId;
        uint256 price;
    }

    mapping(address => mapping(uint256 => Listing)) public listings;
    ExtendERC20Two public erc20Token;
    
    event NFTListed(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price
    );
    
    event NFTBought(
        address indexed buyer,
        address indexed seller,
        address indexed nftAddress,
        uint256 tokenId,
        uint256 price
    );
    
    constructor(address _erc20Token) {
        erc20Token = ExtendERC20Two(_erc20Token);
    }
    
    function list(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _price
    ) external {
        require(
            IERC721(_nftAddress).ownerOf(_tokenId) == msg.sender,
            "Not the owner"
        );
        
        require(
            IERC721(_nftAddress).getApproved(_tokenId) == address(this) ||
            IERC721(_nftAddress).isApprovedForAll(msg.sender, address(this)),
            "Not approved"
        );
        
        require(_price > 0, "Price must be greater than 0");
        
        listings[_nftAddress][_tokenId] = Listing({
            seller: msg.sender,
            nftAddress: _nftAddress,
            tokenId: _tokenId,
            price: _price
        });
        
        emit NFTListed(msg.sender, _nftAddress, _tokenId, _price);
    }
    
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
        
        IERC721(_nftAddress).safeTransferFrom(
            listing.seller,
            msg.sender,
            listing.tokenId
        );
        
        delete listings[_nftAddress][_tokenId];
        
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
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
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