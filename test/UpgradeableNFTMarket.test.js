const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");

describe("UpgradeableNFTMarket", function () {
  let nftMarket;
  let nft;
  let owner;
  let seller;
  let buyer;
  let addrs;

  beforeEach(async function () {
    // 获取测试账户
    [owner, seller, buyer, ...addrs] = await ethers.getSigners();

    // 部署NFT合约
    const NFT = await ethers.getContractFactory("UpgradeableNFT");
    nft = await upgrades.deployProxy(NFT, ["MyNFT", "MNFT"], { initializer: 'initialize' });
    await nft.deployed();

    // 部署NFT市场合约
    const NFTMarket = await ethers.getContractFactory("UpgradeableNFTMarket");
    nftMarket = await upgrades.deployProxy(NFTMarket, [], { initializer: 'initialize' });
    await nftMarket.deployed();
  });

  describe("NFT合约测试", function () {
    it("应该正确设置名称和符号", async function () {
      expect(await nft.name()).to.equal("MyNFT");
      expect(await nft.symbol()).to.equal("MNFT");
    });

    it("应该允许铸造NFT", async function () {
      await nft.connect(seller).mint("ipfs://test");
      expect(await nft.ownerOf(1)).to.equal(seller.address);
    });
  });

  describe("NFT市场测试", function () {
    it("应该允许NFT上架", async function () {
      // 铸造NFT
      await nft.connect(seller).mint("ipfs://test");
      await nft.connect(seller).approve(nftMarket.address, 1);

      // 上架NFT
      const price = ethers.utils.parseEther("1.0");
      await nftMarket.connect(seller).listNFT(nft.address, 1, price);

      // 验证上架信息
      const listing = await nftMarket.listings(nft.address, 1);
      expect(listing.seller).to.equal(seller.address);
      expect(listing.price).to.equal(price);
      expect(listing.isActive).to.be.true;
    });

    it("应该允许购买NFT", async function () {
      // 铸造并上架NFT
      await nft.connect(seller).mint("ipfs://test");
      await nft.connect(seller).approve(nftMarket.address, 1);
      const price = ethers.utils.parseEther("1.0");
      await nftMarket.connect(seller).listNFT(nft.address, 1, price);

      // 购买NFT
      await nftMarket.connect(buyer).buyNFT(nft.address, 1, { value: price });

      // 验证所有权转移
      expect(await nft.ownerOf(1)).to.equal(buyer.address);
    });

    it("应该允许取消上架", async function () {
      // 铸造并上架NFT
      await nft.connect(seller).mint("ipfs://test");
      await nft.connect(seller).approve(nftMarket.address, 1);
      const price = ethers.utils.parseEther("1.0");
      await nftMarket.connect(seller).listNFT(nft.address, 1, price);

      // 取消上架
      await nftMarket.connect(seller).cancelListing(nft.address, 1);

      // 验证上架状态
      const listing = await nftMarket.listings(nft.address, 1);
      expect(listing.isActive).to.be.false;
    });
  });

  describe("升级测试", function () {
    it("应该能够升级NFT合约", async function () {
      const NFTV2 = await ethers.getContractFactory("UpgradeableNFT");
      const upgradedNFT = await upgrades.upgradeProxy(nft.address, NFTV2);
      
      // 验证升级后合约仍然可以正常工作
      await upgradedNFT.connect(seller).mint("ipfs://test");
      expect(await upgradedNFT.ownerOf(1)).to.equal(seller.address);
    });

    it("应该能够升级NFT市场合约", async function () {
      const NFTMarketV2 = await ethers.getContractFactory("UpgradeableNFTMarket");
      const upgradedMarket = await upgrades.upgradeProxy(nftMarket.address, NFTMarketV2);
      
      // 验证升级后合约仍然可以正常工作
      await nft.connect(seller).mint("ipfs://test");
      await nft.connect(seller).approve(upgradedMarket.address, 1);
      const price = ethers.utils.parseEther("1.0");
      await upgradedMarket.connect(seller).listNFT(nft.address, 1, price);
      
      const listing = await upgradedMarket.listings(nft.address, 1);
      expect(listing.seller).to.equal(seller.address);
    });
  });
}); 