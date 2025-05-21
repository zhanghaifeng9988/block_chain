// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin-upgradeable/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin-upgradeable/contracts/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin-upgradeable/contracts/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/utils/ContextUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin-upgradeable/contracts/token/ERC20/IERC20Upgradeable.sol";

contract NFTMarketUpgradeable is Initializable, ContextUpgradeable {
    struct Listing {
        address seller;
        address nftAddress;
        uint256 tokenId;
        uint256 price;
        address paymentToken; // 支付代币地址，address(0) 表示使用 ETH
    }

    mapping(address => mapping(uint256 => Listing)) public listings;

    event NFTListed(address indexed seller, address indexed nftAddress, uint256 indexed tokenId, uint256 price, address paymentToken);
    event NFTBought(address indexed buyer, address indexed seller, address indexed nftAddress, uint256 tokenId, uint256 price, address paymentToken);

    function initialize() public initializer {
        __Context_init();
    }

    function list(address _nftAddress, uint256 _tokenId, uint256 _price) external {
        require(IERC721Upgradeable(_nftAddress).ownerOf(_tokenId) == _msgSender(), "Not the owner");
        require(IERC721Upgradeable(_nftAddress).getApproved(_tokenId) == address(this) || IERC721Upgradeable(_nftAddress).isApprovedForAll(_msgSender(), address(this)), "Not approved");
        require(_price > 0, "Price must be greater than 0");
        listings[_nftAddress][_tokenId] = Listing({
            seller: _msgSender(),
            nftAddress: _nftAddress,
            tokenId: _tokenId,
            price: _price,
            paymentToken: address(0) // 使用 ETH 支付
        });
        emit NFTListed(_msgSender(), _nftAddress, _tokenId, _price, address(0));
    }

    function listWithToken(address _nftAddress, uint256 _tokenId, uint256 _price, address _paymentToken) external {
        require(IERC721Upgradeable(_nftAddress).ownerOf(_tokenId) == _msgSender(), "Not the owner");
        require(IERC721Upgradeable(_nftAddress).getApproved(_tokenId) == address(this) || IERC721Upgradeable(_nftAddress).isApprovedForAll(_msgSender(), address(this)), "Not approved");
        require(_price > 0, "Price must be greater than 0");
        require(_paymentToken != address(0), "Invalid payment token");
        listings[_nftAddress][_tokenId] = Listing({
            seller: _msgSender(),
            nftAddress: _nftAddress,
            tokenId: _tokenId,
            price: _price,
            paymentToken: _paymentToken
        });
        emit NFTListed(_msgSender(), _nftAddress, _tokenId, _price, _paymentToken);
    }

    function buyNFT(address _nftAddress, uint256 _tokenId) external payable {
        Listing memory listing = listings[_nftAddress][_tokenId];
        require(listing.seller != address(0), "NFT not listed");
        require(listing.paymentToken == address(0), "Not ETH payment");
        require(msg.value >= listing.price, "Insufficient payment");
        
        // 转移 NFT
        IERC721Upgradeable(_nftAddress).safeTransferFrom(listing.seller, _msgSender(), listing.tokenId);
        
        // 转移 ETH
        (bool success, ) = listing.seller.call{value: listing.price}("");
        require(success, "ETH transfer failed");
        
        // 如果有额外的 ETH，返还给买家
        if (msg.value > listing.price) {
            (bool refundSuccess, ) = _msgSender().call{value: msg.value - listing.price}("");
            require(refundSuccess, "ETH refund failed");
        }
        
        delete listings[_nftAddress][_tokenId];
        emit NFTBought(_msgSender(), listing.seller, _nftAddress, _tokenId, listing.price, address(0));
    }

    function buyNFTWithToken(address _nftAddress, uint256 _tokenId, uint256 _amount) external {
        Listing memory listing = listings[_nftAddress][_tokenId];
        require(listing.seller != address(0), "NFT not listed");
        require(listing.paymentToken != address(0), "Not token payment");
        require(_amount >= listing.price, "Insufficient payment");

        // 转移 NFT
        IERC721Upgradeable(_nftAddress).safeTransferFrom(listing.seller, _msgSender(), listing.tokenId);
        
        // 转移代币
        require(
            IERC20Upgradeable(listing.paymentToken).transferFrom(_msgSender(), listing.seller, listing.price),
            "Token transfer failed"
        );
        
        delete listings[_nftAddress][_tokenId];
        emit NFTBought(_msgSender(), listing.seller, _nftAddress, _tokenId, listing.price, listing.paymentToken);
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
} 