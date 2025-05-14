// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

//继承了所有 ERC721 标准功能 //增加了存储每个 token URI 的能力
contract MyNFT is ERC721URIStorage {

    using Counters for Counters.Counter;

    //声明一个私有计数器变量//用于跟踪和生成 NFT 的唯一 ID
    Counters.Counter private _tokenIds;
    
    constructor() ERC721("MyNFT", "MNFT") {}
    
    function mintNFT(address recipient, string memory tokenURI) 
        public 
        returns (uint256)
    {
        _tokenIds.increment();//增加计数器值
        
        uint256 newItemId = _tokenIds.current();//获取当前计数器值作为新 NFT ID
        _mint(recipient, newItemId);//铸造 NFT 并分配给 recipient 地址
        _setTokenURI(newItemId, tokenURI);//设置 NFT 的元数据链接
        
        return newItemId;//返回新创建的 NFT ID
    }
}