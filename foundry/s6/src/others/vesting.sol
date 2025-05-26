// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/finance/VestingWallet.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract TokenVesting {
    using SafeERC20 for IERC20;
    
    // 锁仓的ERC20代币地址
    IERC20 public immutable token;
    // 受益人地址
    address public immutable beneficiary;
    // 开始时间戳
    uint256 public immutable start;
    // 锁定期（12个月）
    uint256 public constant CLIFF = 365 days;
    // 归属期（24个月）
    uint256 public constant DURATION = 730 days;
    // 已释放的代币数量
    uint256 private _released;
    
    // 事件：释放代币
    event TokensReleased(address indexed beneficiary, uint256 amount);
    
    constructor(
        address beneficiaryAddress,    // 受益人地址
        address tokenAddress,           // ERC20代币地址
        uint256 startTimestamp         // 开始时间戳
    ) {
        require(beneficiaryAddress != address(0), "TokenVesting: beneficiary is zero address");
        require(tokenAddress != address(0), "TokenVesting: token is zero address");
        beneficiary = beneficiaryAddress;
        token = IERC20(tokenAddress);
        start = startTimestamp;
    }
    
    /**
     * @dev 计算在指定时间点可以释放的代币数量
     */
    function vestedAmount(uint256 timestamp) public view returns (uint256) {
        if (timestamp < start + CLIFF) {
            return 0;
        }
        if (timestamp > start + DURATION) {
            return token.balanceOf(address(this)) + _released;
        }
        
        uint256 totalBalance = token.balanceOf(address(this)) + _released;
        uint256 timeFromStart = timestamp - (start + CLIFF);
        return (totalBalance * timeFromStart) / (DURATION - CLIFF);
    }
    
    /**
     * @dev 释放当前可用的代币到受益人地址
     */
    function release() public {
        uint256 releasable = vestedAmount(block.timestamp) - _released;
        require(releasable > 0, "TokenVesting: no tokens are due");
        
        _released += releasable;
        token.safeTransfer(beneficiary, releasable);
        
        emit TokensReleased(beneficiary, releasable);
    }
    
    /**
     * @dev 返回已释放的代币数量
     */
    function released() public view returns (uint256) {
        return _released;
    }
    
    /**
     * @dev 返回受益人地址
     */
    function getBeneficiary() public view returns (address) {
        return beneficiary;
    }
}