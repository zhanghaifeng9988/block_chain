pragma  solidity  ^0.8.0;
// SPDX-License-Identifier: MIT

contract Bank {
    //定义地址类型的管理员
    address public admin;
    //定义映射类型balances，用于存储余额
    mapping(address=>uint256 ) public balances;
    //定义地址类型的数组，用于存款用户地址的存储
    address[] public users;
    //定义无符号整型数组,用于存储,存款量前3名用户的金额
    uint256[] public topDeposits;
    //定义地址类型的数组，用于存储,存款量前3名用户的地址
    address[] public topUsers;
    
    //定义事件，激发日志，为外部工具提供监听和解析
    //参数被标记为 indexed,它的值会被存储在事件的日志索引中。
    //Deposit事件，记录存款用户的地址，和存款金额
    //外部监听可以实时获取存款用户信息和存款金额
    event Deposit(address indexed user,uint256 amount);
    // Withdraw() 事件，记录管理地址和提取的金额
    // 外部监听可以实时获得管理的操作行为
    event Withdraw(address indexed admin,uint256 amount);
    // TopUserUpdated事件，记录了某个用户进入了存款金额前3名的状态变化。
    // 外部监听可以实时获得存款前三名的用户名和金额信息
    event TopUserUpdated(address indexed user,uint256 amount);

    //定义1个函数装饰器，用于限制某些函数只能由合约的管理员（admin）调用

    modifier onlyAdmin() {
        require(msg.sender == admin,"Only admin can perform this operation");
        _;//占位符，表示被修饰函数的主体代码将在这里执行。

    }

    //构造函数，该合约被部署后执行该函数，用于初始化管理员账户地址！
    constructor() {
        admin = msg.sender;
    }

    //用户存款的业务逻辑函数，payable表示这个函数可以接收以太币
    function deposit() external  payable {
        require(msg.value > 0,"Deposit amount must be greater than zero");

        //判断用户是不是第一次存钱，是的话，就创建用户的存款账户
        if (balances[msg.sender] == 0){
            users.push(msg.sender);
        }

        //设置用户余额为当前合约接收的以太币数量，balances这个映射类型的存储状态变量被赋值
        balances[msg.sender]+=msg.value;

        //触发Deposit事件，传递存款用户地址和存款金额
        emit Deposit(msg.sender,msg.value);

        //调用updateTopUsers函数，传入存款用户地址和存款金额
        updateTopUsers(msg.sender,msg.value);
    }

        //定义管理员操作账户金额的函数，
    //装饰器使用已经定义好的onlyAdmin，用于判断用户是否为管理员
    function withdraw() external onlyAdmin {
        uint256 amount = address(this).balance;
        require(amount>0,"no funds to withdraw");

        //将合约中的以太币（ETH）转账给管理员的地址
        payable(admin).transfer(amount);
    }
    
        // 对存款用户进行排序，将前三名推入定义的两个数组中
    function  updateTopUsers (address user,uint256 amount) internal {
        // 如果存款金额最多的用户不足三个，直接将当前用户和他的存款金额推入对应数组
        if(topUsers.length < 3) {
            topUsers.push(user);
            topDeposits.push(amount);
        }
        else {//将当前用户存款金额与已经存在的三个金额进行循环比对，如果大于某1个旧的存在值，就替换掉
            for (uint256 i=0;i<3;i++){
                if (amount > topDeposits[i]){
                    topUsers[i]=user;
                    topDeposits[i]=amount;
                    break;
                }
            }
        }

        //触发事件，将最新的3个金额最多的存款用户信息，发布出去，并执行日志记录
        emit  TopUserUpdated(user, amount);
    }

    //返回当前合约中存储的顶级用户及其对应的存款金额。
    function getTopUsers() external view returns (address[] memory, uint256[] memory) {
        return (topUsers, topDeposits);
    }

    //返回传入的用户（指定用户）在合约中的余额
    function getUserBalance(address user) external view returns (uint256) {
        return balances[user];
    }

    //返回本合约当前的以太坊余额。
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}