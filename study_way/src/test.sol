pragma solidity ^0.8.0;

contract Bank {
    address public admin;
    mapping(address => uint256) public balances;
    address[] public users;
    uint256[] public topDeposits;
    address[] public topUsers;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed admin, uint256 amount);
    event TopUserUpdated(address indexed user, uint256 amount);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    function deposit() external payable {
        require(msg.value > 0, "Deposit amount must be greater than zero");

        if (balances[msg.sender] == 0) {
            users.push(msg.sender);
        }

        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);

        updateTopUsers(msg.sender, msg.value);
    }

    function withdraw() external onlyAdmin {
        uint256 amount = address(this).balance;
        require(amount > 0, "No funds to withdraw");

        payable(admin).transfer(amount);
        emit Withdraw(admin, amount);
    }

    function updateTopUsers(address user, uint256 amount) internal {
        if (topUsers.length < 3) {
            topUsers.push(user);
            topDeposits.push(amount);
        } else {
            for (uint256 i = 0; i < 3; i++) {
                if (amount > topDeposits[i]) {
                    topUsers[i] = user;
                    topDeposits[i] = amount;
                    break;
                }
            }
        }

        emit TopUserUpdated(user, amount);
    }

    function getTopUsers() external view returns (address[] memory, uint256[] memory) {
        return (topUsers, topDeposits);
    }

    function getUserBalance(address user) external view returns (uint256) {
        return balances[user];
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}