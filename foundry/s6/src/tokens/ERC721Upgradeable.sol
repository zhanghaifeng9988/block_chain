// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin-upgradeable/contracts/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin-upgradeable/contracts/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/proxy/utils/Initializable.sol";

contract ERC721UpgradeableNFT is Initializable, ERC721Upgradeable, ERC721URIStorageUpgradeable {
    uint256 private _tokenIds;

    function initialize(string memory name_, string memory symbol_) public initializer {
        __ERC721_init(name_, symbol_);
        __ERC721URIStorage_init();
    }

    function mintNFT(address recipient, string memory uri) public returns (uint256) {
        _tokenIds++;
        uint256 newItemId = _tokenIds;
        _safeMint(recipient, newItemId);
        _setTokenURI(newItemId, uri);
        return newItemId;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721Upgradeable, ERC721URIStorageUpgradeable) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721Upgradeable, ERC721URIStorageUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // 解决多重继承的 _burn 冲突
    function _burn(uint256 tokenId) internal override(ERC721Upgradeable, ERC721URIStorageUpgradeable) {
        super._burn(tokenId);
    }
} 