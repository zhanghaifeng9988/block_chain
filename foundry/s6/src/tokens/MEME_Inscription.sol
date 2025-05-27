// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./MEME_Token.sol";

/**
 * @title MEME_Inscription 合约
 * @dev 这是一个用于创建和管理 MEME 代币的工厂合约
 * 使用最小代理模式来减少 gas 成本
 */
contract MEME_Inscription {
    // immutable 关键字表示这个变量只能在构造函数中设置一次，之后不能修改
    // 存储 MEME 代币的实现合约地址
    address public immutable implementation;
    
    // 平台所有者地址，用于收取平台费用
    address public owner;
    
    /**
     * @dev MEME 代币的相关信息结构体
     */
    struct MemeInfo {
        uint256 perMint;    // 每次铸造的代币数量
        uint256 price;      // 每个代币的价格（以 wei 为单位）
        address creator;    // 代币创建者地址
    }
    
    // 存储每个代币合约地址对应的 MemeInfo 信息
    mapping(address => MemeInfo) public memeInfos;
    
    // 事件：当新的 MEME 代币被部署时触发
    event MemeDeployed(address indexed token, string symbol, uint256 totalSupply, uint256 perMint, uint256 price);
    // 事件：当 MEME 代币被铸造时触发
    event MemeMinted(address indexed token, address indexed minter, uint256 amount);

    /**
     * @dev 构造函数
     * 部署一个基础的 MEME_Token 实现合约，作为所有代理合约的模板
     */
    constructor() {
        implementation = address(new MEME_Token());
        owner = msg.sender;
    }

    /**
     * @dev 部署新的 MEME 代币
     * @param symbol 代币符号
     * @param totalSupply 代币总供应量
     * @param perMint 每次铸造的数量
     * @param price 每个代币的价格（wei）
     * @return 新部署的代币合约地址
     */
    function deployInscription(
        string memory symbol,
        uint256 totalSupply,
        uint256 perMint,
        uint256 price
    ) external returns (address) {
        // 验证参数的合法性
        require(perMint > 0 && perMint <= totalSupply, "Invalid perMint");
        require(perMint == 10, "perMint must be 10");
        require(price == 100, "Invalid price");

        // 使用最小代理模式部署新的代币合约
        address proxy = createClone(implementation);
        // 初始化代理合约 ，address(this) 是 MEME_Inscription 工厂合约的地址
        MEME_Token(proxy).initialize(symbol, totalSupply, address(this));
        
        // 存储代币相关信息
        memeInfos[proxy] = MemeInfo({
            perMint: perMint,
            price: price,
            creator: msg.sender
        });

        // 触发部署事件
        emit MemeDeployed(proxy, symbol, totalSupply, perMint, price);
        return proxy;
    }

    /**
     * @dev 铸造 MEME 代币
     * @param tokenAddr 要铸造的代币合约地址，是代理合约的地址，
     * 该函数是 payable 的，调用时需要附带足够的 ETH
     */
    function mintInscription(address tokenAddr) external payable {
        MemeInfo storage info = memeInfos[tokenAddr];
        require(info.creator != address(0), "Token not found");
        require(MEME_Token(tokenAddr).minted() + info.perMint <= MEME_Token(tokenAddr).totalSupply(), "Exceeds total supply");
        require(msg.value >= info.price * info.perMint, "Insufficient payment");

        // 计算费用分配
        uint256 totalFee = info.price * info.perMint;
        uint256 platformFee = totalFee / 100;  // 平台收取 1% 费用
        uint256 creatorFee = totalFee - platformFee;

        // 铸造代币给购买者  msg.sender是用户得钱包地址，当前调用这个mintInscription函数
        MEME_Token(tokenAddr).mint(msg.sender, info.perMint);

        // 转账费用给平台和创建者
        (bool success1, ) = payable(owner).call{value: platformFee}("");
        require(success1, "Platform fee transfer failed");
        (bool success2, ) = payable(info.creator).call{value: creatorFee}("");
        require(success2, "Creator fee transfer failed");

        emit MemeMinted(tokenAddr, msg.sender, info.perMint);
    }

    /**
     * @dev 创建最小代理合约
     * @param target 目标实现合约地址
     * @return result 新创建的代理合约地址
     * 使用内联汇编实现 EIP-1167 最小代理模式
     */
    function createClone(address target) internal returns (address result) {
        bytes20 targetBytes = bytes20(target);
        assembly {
            // 加载空闲内存指针
            let clone := mload(0x40)
            // 存储代理合约的字节码
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            // 存储目标合约地址
            mstore(add(clone, 0x14), targetBytes)
            // 存储剩余的代理合约字节码
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            // 创建新的合约
            result := create(0, clone, 0x37)
        }
    }
} 