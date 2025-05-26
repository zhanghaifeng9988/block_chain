// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import "../tokens/Permit2Token.sol";
import { ISignatureTransfer } from "@uniswap/permit2/src/interfaces/ISignatureTransfer.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import { Permit2 } from "permit2/src/Permit2.sol";

contract Permit2TokenBank {
    // 代币合约地址
    Permit2Token public token;
    // Permit2合约地址
    ISignatureTransfer public permit2;
    // Admin address
    address public admin;
    // 记录每个接收代币钱包用户的存款余额
    mapping(address => uint256) public balances;

    // 事件：存款
    event Deposited(address indexed user, address indexed to, uint256 amount);
    // 事件：通过permit2存款
    event Permit2Deposited(address indexed user, address indexed to, uint256 amount);
    // 调试事件
    event DebugStep(string step);
    // 事件：提款（管理员操作）
    event Withdrawn(address indexed admin, uint256 amount);
    // 事件：提款（用户操作）
    event UserWithdrawn(address indexed user, uint256 amount);

    constructor(address _token, address _permit2) {
        // Ensure the Permit2 contract address is valid
        require(_permit2 != address(0), "Permit2 address cannot be zero");
        // Ensure the token contract address is valid
        require(_token != address(0), "Token address cannot be zero");

        token = Permit2Token(_token);
        permit2 = ISignatureTransfer(_permit2);
        admin = msg.sender;
    }

    // Modifier to restrict calls to only come from the Permit2 contract
    modifier onlyPermit2(address _permit2) {
        require(msg.sender == _permit2, "Permit2Bank: Caller is not Permit2");
        _;
    }

    // 标准存款函数
    function deposit(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        bool success = token.transferFrom(msg.sender, address(this), amount);
        require(success, "Transfer failed");
        balances[msg.sender] += amount;
        emit Deposited(msg.sender, address(this), amount);
    }

    // 使用Uniswap Permit2进行存款的函数
    function depositWithPermit2(
        ISignatureTransfer.PermitTransferFrom memory permit,
        bytes calldata signature,
        uint256 amount
    ) external {
        require(amount > 0, "Amount must be greater than 0");
        emit DebugStep("depositWithPermit2: Started");
        
        // 直接使用permitTransferFrom，不创建额外的结构体
        emit DebugStep("depositWithPermit2: Before permitTransferFrom");
        permit2.permitTransferFrom(
            permit,
            ISignatureTransfer.SignatureTransferDetails({
                to: address(this),
                requestedAmount: amount
            }),
            msg.sender,
            signature
        );
        emit DebugStep("depositWithPermit2: After permitTransferFrom");
        
        balances[msg.sender] += amount;
        emit DebugStep("depositWithPermit2: Balances updated");
        emit Permit2Deposited(msg.sender, address(this), amount);
        emit DebugStep("depositWithPermit2: Finished");
    }

    // 使用EIP-2612 Permit进行存款的函数
    function permitDeposit(
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(amount > 0, "Amount must be greater than 0");

        // 使用permit签名获取授权
        IERC20Permit(address(token)).permit(msg.sender, address(this), amount, deadline, v, r, s);

        // 从用户转移代币到银行合约
        bool success = token.transferFrom(msg.sender, address(this), amount);
        require(success, "Transfer failed");

        // 更新余额
        balances[msg.sender] += amount;

        emit Deposited(msg.sender, address(this), amount);
    }

    // 用户提款函数
    function userWithdraw(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        require(balances[msg.sender] >= amount, "Insufficient balance");

        balances[msg.sender] -= amount;
        bool success = token.transfer(msg.sender, amount);
        require(success, "Transfer failed");

        emit UserWithdrawn(msg.sender, amount);
    }

    // 管理员提取所有代币
    function withdraw() external {
        require(msg.sender == admin, "Only admin can withdraw");
        uint256 totalBalance = token.balanceOf(address(this));
        require(totalBalance > 0, "No tokens to withdraw");

        bool success = token.transfer(admin, totalBalance);
        require(success, "Withdrawal failed");

        emit Withdrawn(admin, totalBalance);
    }

    // 查询合约当前持有的代币余额
    function getBankBalance() external view returns (uint256) {
        return token.balanceOf(address(this));
    }

    // 查询用户存款余额
    function getDepositRecord(address user) external view returns (uint256) {
        return balances[user];
    }

    // 新增的测试函数
    function testPermitTransferFrom(
        ISignatureTransfer.PermitTransferFrom memory permit,
        bytes calldata signature,
        address owner,
        uint256 requestedAmount
    ) external {
        emit DebugStep("testPermitTransferFrom: Started");
        
        permit2.permitTransferFrom(
            permit,
            ISignatureTransfer.SignatureTransferDetails({
                to: address(this),
                requestedAmount: requestedAmount
            }),
            owner,
            signature
        );
        emit DebugStep("testPermitTransferFrom: Finished");
    }
} 