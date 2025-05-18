/**
 *Submitted for verification at Etherscan.io on 2017-04-06
*/

contract MultiSigWallet {
 uint constant public MAX_OWNER_COUNT = 50;

    event Confirmation(address indexed sender, uint indexed transactionId);
    event Revocation(address indexed sender, uint indexed transactionId);
    event Submission(uint indexed transactionId);
    event Execution(uint indexed transactionId);
    event ExecutionFailure(uint indexed transactionId);
    event Deposit(address indexed sender, uint value);
    event OwnerAddition(address indexed owner);
    event OwnerRemoval(address indexed owner);
    event RequirementChange(uint required);

    mapping (uint => Transaction) public transactions;
    mapping (uint => mapping (address => bool)) public confirmations;
    mapping (address => bool) public isOwner;
    address[] public owners;
    uint public required;
    uint public transactionCount;

    struct Transaction {
        address destination;
        uint value;
        bytes data;
        bool executed;
    }

    modifier onlyWallet() {
        if (msg.sender != address(this))
            throw;
        _;
    }

    modifier ownerDoesNotExist(address owner) {
        if (isOwner[owner])
            throw;
        _;
    }

    modifier ownerExists(address owner) {
        if (!isOwner[owner])
            throw;
        _;
    }

    modifier transactionExists(uint transactionId) {
        if (transactions[transactionId].destination == 0)
            throw;
        _;
    }

    modifier confirmed(uint transactionId, address owner) {
        if (!confirmations[transactionId][owner])
            throw;
        _;
    }

    modifier notConfirmed(uint transactionId, address owner) {
        if (confirmations[transactionId][owner])
            throw;
        _;
    }

    modifier notExecuted(uint transactionId) {
        if (transactions[transactionId].executed)
            throw;
        _;
    }

    modifier notNull(address _address) {
        if (_address == 0)
            throw;
        _;
    }

    modifier validRequirement(uint ownerCount, uint _required) {
        if (   ownerCount > MAX_OWNER_COUNT
            || _required > ownerCount
            || _required == 0
            || ownerCount == 0)
            throw;
        _;
    }

    payable 修饰的函数是合约接收 ETH 的关键入口，
    这个函数展示了一个典型的多签钱包的 ETH 接收函数。
    /// @dev Fallback function allows to deposit ether.
    function()
        payable
    {
        if (msg.value > 0)
            Deposit(msg.sender, msg.value);
    }


在以太坊中，多签钱包往往是一个智能合约。
/* 1. 构造多签合约的调用者权限
constructor 构造方法是合约创建时触发调用的，
通过传入 onwers 参数传入授权的多个钱包地址，以及 required 参数表示最少签名人数。
即以M/N多签模式为例，N表示 owners.length ，N表示 required */

    /*
     * Public functions
     */
    /// @dev Contract constructor sets initial owners and required number of confirmations.
    /// @param _owners List of initial owners.
    /// @param _required Number of required confirmations.
    function MultiSigWallet(address[] _owners, uint _required)
        public
        validRequirement(_owners.length, _required)//装饰器，检查参数是否有效
    {
        for (uint i=0; i<_owners.length; i++) {
            if (isOwner[_owners[i]] || _owners[i] == 0)
                throw;
            isOwner[_owners[i]] = true;
        }
        owners = _owners;
        required = _required;
    }

    /// @dev Allows to add a new owner. Transaction has to be sent by wallet.
    /// @param owner Address of new owner.
    function addOwner(address owner)
        public
        onlyWallet
        ownerDoesNotExist(owner)
        notNull(owner)
        validRequirement(owners.length + 1, required)
    {
        isOwner[owner] = true;
        owners.push(owner);
        OwnerAddition(owner);
    }

    /// @dev Allows to remove an owner. Transaction has to be sent by wallet.
    /// @param owner Address of owner.
    function removeOwner(address owner)
        public
        onlyWallet
        ownerExists(owner)
    {
        isOwner[owner] = false;
        for (uint i=0; i<owners.length - 1; i++)
            if (owners[i] == owner) {
                owners[i] = owners[owners.length - 1];
                break;
            }
        owners.length -= 1;
        if (required > owners.length)
            changeRequirement(owners.length);
        OwnerRemoval(owner);
    }

    /// @dev Allows to replace an owner with a new owner. Transaction has to be sent by wallet.
    /// @param owner Address of owner to be replaced.
    /// @param owner Address of new owner.
    function replaceOwner(address owner, address newOwner)
        public
        onlyWallet
        ownerExists(owner)
        ownerDoesNotExist(newOwner)
    {
        for (uint i=0; i<owners.length; i++)
            if (owners[i] == owner) {
                owners[i] = newOwner;
                break;
            }
        isOwner[owner] = false;
        isOwner[newOwner] = true;
        OwnerRemoval(owner);
        OwnerAddition(newOwner);
    }

    /// @dev Allows to change the number of required confirmations. Transaction has to be sent by wallet.
    /// @param _required Number of required confirmations.
    function changeRequirement(uint _required)
        public
        onlyWallet
        validRequirement(owners.length, _required)
    {
        required = _required;
        RequirementChange(_required);
    }


    2. 提交多签钱包交易申请
    submitTransaction 方法的作用是多签名人,
    任一一方提交交易申请，返回一个交易号（transactionId 后面会用到）。
    参数 destination 是接受人的钱包地址，
    value 为转出的 ether 数量（以 wei 为单位），
    data 是该交易的数据。data 参数可以传入任意数组来实现任意功能，
    比如如果转出ETH那么此参数是[] (空)，如果转出ERC20代码(如USDT)，
    则此参数是ERC20 transfer 方法的哈希和参数 （[0]:xxxxx [1]:xxxxx）。
    /// @dev Allows an owner to submit and confirm a transaction.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @param data Transaction data payload.
    /// @return Returns transaction ID.
    function submitTransaction(address destination, uint value, bytes data)
        public
        returns (uint transactionId)
    {
        transactionId = addTransaction(destination, value, data);
        confirmTransaction(transactionId);
    }


    3. 其余签名人对交易确认
     confirmTransaction 方法的作用是其他参与签名的人发起确认以表示对某个交易执行的认可。
     参数就是 submitTransaction 流程里提交交易申请时产生的交易号。
     当然参与者也可以拒绝认可，下面一个 revokeConfirmation 方法来提供拒绝的行为，
     可以去合约代码里查看。
    

    /// @dev Allows an owner to confirm a transaction.
    /// @param transactionId Transaction ID.
    function confirmTransaction(uint transactionId)
        public
        ownerExists(msg.sender)//装饰器，检查调用者是否是多签注册人之一
        transactionExists(transactionId)//检查交易是否存在
        notConfirmed(transactionId, msg.sender)//检查调用者是否已经确认过该交易
    {
        confirmations[transactionId][msg.sender] = true;
        Confirmation(msg.sender, transactionId);
        executeTransaction(transactionId);
    }

    /// @dev Allows an owner to revoke a confirmation for a transaction.
    /// @param transactionId Transaction ID.
    function revokeConfirmation(uint transactionId)
        public
        ownerExists(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        confirmations[transactionId][msg.sender] = false;
        Revocation(msg.sender, transactionId);
    }

    4. 正式执行交易操作，
    当确认的人数达到最低（required）要求，
    **executeTransaction** 的内部逻辑将被触发，
    从而执行第一步用户所提交的逻辑。
    当 executeTransaction 内部逻辑被触发，
    即完成了多签合约的真正调用，
    如上所述，value 和 data 可以控制多签执行任意逻辑（转移 ether 或 ERC20 代币等）。

    /// @dev Allows anyone to execute a confirmed transaction.
    /// @param transactionId Transaction ID.
    function executeTransaction(uint transactionId)
        public
        notExecuted(transactionId)
    {
        if (isConfirmed(transactionId)) {
            Transaction tx = transactions[transactionId];
            tx.executed = true;
            if (tx.destination.call.value(tx.value)(tx.data))
                Execution(transactionId);
            else {
                ExecutionFailure(transactionId);
                tx.executed = false;
            }
        }
    }


    /**
 * 10. 检查交易确认状态
 * isConfirmed 方法用于检查某个交易是否已经达到所需的确认数量。
 * 通过遍历所有所有者，统计已确认的数量，当达到 required（所需确认数）时返回 true。
 * 这个函数在 executeTransaction 执行前会被调用，用于验证交易是否满足执行条件。
 * @param transactionId 交易ID
 * @return bool 如果达到所需确认数返回 true，否则返回 false
 */
    /// @dev Returns the confirmation status of a transaction.
    /// @param transactionId Transaction ID.
    /// @return Confirmation status.
    function isConfirmed(uint transactionId)
        public
        constant
        returns (bool)
    {
        uint count = 0;
        for (uint i=0; i<owners.length; i++) {
            if (confirmations[transactionId][owners[i]])
                count += 1;
            if (count == required)
                return true;
        }
    }

    /**
 * 11. 添加新交易
 * addTransaction 是一个内部函数，用于在交易映射中添加新的交易记录。
 * 当多签所有者提交新交易时，会调用此函数创建交易记录。
 * 每个交易都会被分配一个唯一的 transactionId，并记录交易的目标地址、转账金额和数据。
 * @param destination 交易目标地址（接收方地址）
 * @param value 交易金额（以 wei 为单位的 ETH 数量）
 * @param data 交易数据（可以是空数组，也可以是调用其他合约的数据）
 * @return transactionId 新创建的交易ID
 */
    /*
     * Internal functions
     */
    /// @dev Adds a new transaction to the transaction mapping, if transaction does not exist yet.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @param data Transaction data payload.
    /// @return Returns transaction ID.
    function addTransaction(address destination, uint value, bytes data)
        internal
        notNull(destination)
        returns (uint transactionId)
    {
        transactionId = transactionCount;
        transactions[transactionId] = Transaction({
            destination: destination,
            value: value,
            data: data,
            executed: false
        });
        transactionCount += 1;
        Submission(transactionId);
    }


        /**
 * 5. 查询交易确认数量
 * getConfirmationCount 方法用于查询某个交易已经获得的确认数量。
 * 通过遍历所有所有者，统计已确认的数量。
 * @param transactionId 交易ID
 * @return count 确认数量
 */
    /*
     * Web3 call functions
     */
    /// @dev Returns number of confirmations of a transaction.
    /// @param transactionId Transaction ID.
    /// @return Number of confirmations.
    function getConfirmationCount(uint transactionId)
        public
        constant
        returns (uint count)
    {
        for (uint i=0; i<owners.length; i++)
            if (confirmations[transactionId][owners[i]])
                count += 1;
    }

    /**
 * 6. 获取交易数量
 * getTransactionCount 方法用于获取符合条件的交易总数。
 * 可以根据 pending（待处理）和 executed（已执行）两个条件进行筛选。
 * @param pending 是否包含待处理的交易
 * @param executed 是否包含已执行的交易
 * @return count 符合条件的交易总数
 */

    /// @dev Returns total number of transactions after filers are applied.
    /// @param pending Include pending transactions.
    /// @param executed Include executed transactions.
    /// @return Total number of transactions after filters are applied.
    function getTransactionCount(bool pending, bool executed)
        public
        constant
        returns (uint count)
    {
        for (uint i=0; i<transactionCount; i++)
            if (   pending && !transactions[i].executed
                || executed && transactions[i].executed)
                count += 1;
    }


    /**
 * 7. 获取所有者列表
 * getOwners 方法用于获取当前所有多签所有者的地址列表。
 * @return 所有者地址数组
 */

    /// @dev Returns list of owners.
    /// @return List of owner addresses.
    function getOwners()
        public
        constant
        returns (address[])
    {
        return owners;
    }

    /**
 * 8. 获取交易确认者列表
 * getConfirmations 方法用于获取已确认某个交易的所有者地址列表。
 * 通过遍历所有所有者，收集已确认该交易的所有者地址。
 * @param transactionId 交易ID
 * @return _confirmations 确认者地址数组
 */

    /// @dev Returns array with owner addresses, which confirmed transaction.
    /// @param transactionId Transaction ID.
    /// @return Returns array of owner addresses.
    function getConfirmations(uint transactionId)
        public
        constant
        returns (address[] _confirmations)
    {
        address[] memory confirmationsTemp = new address[](owners.length);
        uint count = 0;
        uint i;
        for (i=0; i<owners.length; i++)
            if (confirmations[transactionId][owners[i]]) {
                confirmationsTemp[count] = owners[i];
                count += 1;
            }
        _confirmations = new address[](count);
        for (i=0; i<count; i++)
            _confirmations[i] = confirmationsTemp[i];
    }

    /**
 * 9. 获取交易ID列表
 * getTransactionIds 方法用于获取指定范围内的交易ID列表。
 * 可以根据 pending（待处理）和 executed（已执行）两个条件进行筛选，
 * 并支持指定返回的起始和结束位置。
 * @param from 起始索引位置
 * @param to 结束索引位置
 * @param pending 是否包含待处理的交易
 * @param executed 是否包含已执行的交易
 * @return _transactionIds 符合条件的交易ID数组
 */

    /// @dev Returns list of transaction IDs in defined range.
    /// @param from Index start position of transaction array.
    /// @param to Index end position of transaction array.
    /// @param pending Include pending transactions.
    /// @param executed Include executed transactions.
    /// @return Returns array of transaction IDs.
    function getTransactionIds(uint from, uint to, bool pending, bool executed)
        public
        constant
        returns (uint[] _transactionIds)
    {
        uint[] memory transactionIdsTemp = new uint[](transactionCount);
        uint count = 0;
        uint i;
        for (i=0; i<transactionCount; i++)
            if (   pending && !transactions[i].executed
                || executed && transactions[i].executed)
            {
                transactionIdsTemp[count] = i;
                count += 1;
            }
        _transactionIds = new uint[](to - from);
        for (i=from; i<to; i++)
            _transactionIds[i - from] = transactionIdsTemp[i];
    }
}

