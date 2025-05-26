// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.6.6;

import './UniswapV2ERC20.sol';
import '../interfaces/IUniswapV2Pair.sol';
import '../libraries/Math.sol';
import '../libraries/UQ112x112.sol';
import '../interfaces/IERC20.sol';
import '../interfaces/IUniswapV2Factory.sol';
import '../interfaces/IUniswapV2Callee.sol';

// Uniswap V2 交易对合约：实现了自动做市商(AMM)的核心逻辑
contract UniswapV2Pair is IUniswapV2Pair, UniswapV2ERC20 {
    // 使用 UQ112x112 库进行定点数运算
    using UQ112x112 for uint224;

    // 最小流动性代币数量：永久锁定在合约中，防止首次流动性提供者操纵价格
    uint public constant MINIMUM_LIQUIDITY = 10**3;
    
    // 用于 transfer 调用的函数选择器
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    // 状态变量：工厂合约地址
    address public factory;
    // 状态变量：代币地址（按大小排序）
    address public token0;
    address public token1;

    // 状态变量：代币储备量和最后更新时间
    // reserve0, reserve1：两种代币的当前储备量
    // blockTimestampLast：最后一次更新储备量的区块时间戳
    uint112 private reserve0;           
    uint112 private reserve1;           
    uint32  private blockTimestampLast; 

    // 状态变量：价格累积值，用于计算时间加权平均价格(TWAP)
    uint public price0CumulativeLast;
    uint public price1CumulativeLast;
    
    // 状态变量：储备金乘积的最后值，用于计算协议费用
    uint public kLast; 

    // 存储锁，防止重入攻击
    uint private unlocked = 1;

    // 修饰器：防止重入攻击
    modifier lock() {
        require(unlocked == 1, 'UniswapV2: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    // 函数：获取当前储备量和最后更新时间
    function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    // 内部函数：安全转移代币
    function _safeTransfer(address token, address to, uint value) private {
        // 调用代币合约的 transfer 函数
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        // 检查调用是否成功且返回值为 true
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'UniswapV2: TRANSFER_FAILED');
    }

    // 构造函数
    constructor() public {
        factory = msg.sender;
    }

    // 初始化函数：只能被工厂合约调用一次
    function initialize(address _token0, address _token1) external {
        require(msg.sender == factory, 'UniswapV2: FORBIDDEN');
        token0 = _token0;
        token1 = _token1;
    }

    // 内部函数：更新储备量和价格累积值
    function _update(uint balance0, uint balance1, uint112 _reserve0, uint112 _reserve1) private {
        // 检查余额不超过 uint112 的最大值
        require(balance0 <= uint112(-1) && balance1 <= uint112(-1), 'UniswapV2: OVERFLOW');
        
        // 获取当前区块时间戳
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        // 计算时间流逝
        uint32 timeElapsed = blockTimestamp - blockTimestampLast;
        
        // 如果时间有流逝且储备量不为零，更新价格累积值
        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            // 使用 UQ112x112 进行定点数运算计算价格累积值
            price0CumulativeLast += uint(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
            price1CumulativeLast += uint(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
        }

        // 更新储备量和时间戳
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        
        // 触发同步事件
        emit Sync(reserve0, reserve1);
    }

    // 内部函数：如果开启了协议费用，铸造费用代币
    function _mintFee(uint112 _reserve0, uint112 _reserve1) private returns (bool feeOn) {
        // 从工厂合约获取费用接收地址
        address feeTo = IUniswapV2Factory(factory).feeTo();
        // 检查是否开启了协议费用
        feeOn = feeTo != address(0);
        
        // 获取储备金乘积的最后值
        uint _kLast = kLast;
        // 如果开启了费用且 kLast 不为零
        if (feeOn) {
            if (_kLast != 0) {
                // 计算储备金乘积的平方根
                uint rootK = Math.sqrt(uint(_reserve0) * uint(_reserve1));
                uint rootKLast = Math.sqrt(_kLast);
                
                // 如果储备金乘积增加了
                if (rootK > rootKLast) {
                    // 计算并铸造协议费用代币
                    uint numerator = totalSupply * (rootK - rootKLast);
                    uint denominator = rootK * 5 + rootKLast;
                    uint liquidity = numerator / denominator;
                    // 将费用代币铸造给接收地址
                    if (liquidity > 0) _mint(feeTo, liquidity);
                }
            }
        // 如果关闭了费用，但 kLast 不为零，将其设为零
        } else if (_kLast != 0) {
            kLast = 0;
        }
    }

    // 函数：添加流动性，返回铸造的流动性代币数量
    function mint(address to) external lock returns (uint liquidity) {
        // 获取当前储备量
        (uint112 _reserve0, uint112 _reserve1,) = getReserves();
        
        // 获取当前合约中的代币余额
        uint balance0 = IERC20(token0).balanceOf(address(this));
        uint balance1 = IERC20(token1).balanceOf(address(this));
        
        // 计算存入的代币数量
        uint amount0 = balance0 - _reserve0;
        uint amount1 = balance1 - _reserve1;

        // 检查是否需要收取协议费用
        bool feeOn = _mintFee(_reserve0, _reserve1);
        
        // 获取当前总供应量
        uint _totalSupply = totalSupply;
        
        // 如果是首次添加流动性
        if (_totalSupply == 0) {
            // 使用存入代币数量的几何平均数作为初始流动性
            liquidity = Math.sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;
            // 永久锁定最小流动性
            _mint(address(0), MINIMUM_LIQUIDITY);
        } else {
            // 否则，按比例计算应该铸造的流动性代币数量
            liquidity = Math.min(
                (amount0 * _totalSupply) / _reserve0,
                (amount1 * _totalSupply) / _reserve1
            );
        }
        
        // 检查铸造的流动性代币数量是否大于 0
        require(liquidity > 0, 'UniswapV2: INSUFFICIENT_LIQUIDITY_MINTED');
        
        // 铸造流动性代币
        _mint(to, liquidity);

        // 更新储备量
        _update(balance0, balance1, _reserve0, _reserve1);
        
        // 如果开启了协议费用，更新 kLast
        if (feeOn) kLast = uint(reserve0) * uint(reserve1);
        
        // 触发添加流动性事件
        emit Mint(msg.sender, amount0, amount1);
    }

    // 函数：移除流动性，返回返还的代币数量
    function burn(address to) external lock returns (uint amount0, uint amount1) {
        // 获取当前储备量
        (uint112 _reserve0, uint112 _reserve1,) = getReserves();
        
        // 获取代币地址和当前合约中的代币余额
        address _token0 = token0;
        address _token1 = token1;
        uint balance0 = IERC20(_token0).balanceOf(address(this));
        uint balance1 = IERC20(_token1).balanceOf(address(this));
        
        // 获取待销毁的流动性代币数量
        uint liquidity = balanceOf[address(this)];

        // 检查是否需要收取协议费用
        bool feeOn = _mintFee(_reserve0, _reserve1);
        
        // 获取当前总供应量
        uint _totalSupply = totalSupply;
        
        // 按比例计算应该返还的代币数量
        amount0 = (liquidity * balance0) / _totalSupply;
        amount1 = (liquidity * balance1) / _totalSupply;
        
        // 检查返还的代币数量是否大于 0
        require(amount0 > 0 && amount1 > 0, 'UniswapV2: INSUFFICIENT_LIQUIDITY_BURNED');
        
        // 销毁流动性代币
        _burn(address(this), liquidity);
        
        // 转移代币给接收地址
        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);
        
        // 更新合约中的代币余额
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));

        // 更新储备量
        _update(balance0, balance1, _reserve0, _reserve1);
        
        // 如果开启了协议费用，更新 kLast
        if (feeOn) kLast = uint(reserve0) * uint(reserve1);
        
        // 触发移除流动性事件
        emit Burn(msg.sender, amount0, amount1, to);
    }

    // 函数：交换代币
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external lock {
        // 检查输出数量是否大于 0
        require(amount0Out > 0 || amount1Out > 0, 'UniswapV2: INSUFFICIENT_OUTPUT_AMOUNT');
        
        // 获取当前储备量
        (uint112 _reserve0, uint112 _reserve1,) = getReserves();
        
        // 检查输出数量是否超过储备量
        require(amount0Out < _reserve0 && amount1Out < _reserve1, 'UniswapV2: INSUFFICIENT_LIQUIDITY');

        // 初始化中间变量
        uint balance0;
        uint balance1;
        { 
            // 获取代币地址
            address _token0 = token0;
            address _token1 = token1;
            
            // 检查接收地址不是代币地址
            require(to != _token0 && to != _token1, 'UniswapV2: INVALID_TO');
            
            // 如果有输出，转移代币
            if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out);
            if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out);
            
            // 如果提供了回调数据，执行回调
            if (data.length > 0) IUniswapV2Callee(to).uniswapV2Call(msg.sender, amount0Out, amount1Out, data);
            
            // 获取当前合约中的代币余额
            balance0 = IERC20(_token0).balanceOf(address(this));
            balance1 = IERC20(_token1).balanceOf(address(this));
        }
        
        // 计算实际输入的代币数量
        uint amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        
        // 检查是否有输入
        require(amount0In > 0 || amount1In > 0, 'UniswapV2: INSUFFICIENT_INPUT_AMOUNT');

        { 
            // 检查交易是否满足恒定乘积公式（k = x * y）
            // 计算手续费后的余额
            uint balance0Adjusted = (balance0 * 1000) - (amount0In * 3);
            uint balance1Adjusted = (balance1 * 1000) - (amount1In * 3);
            require(
                balance0Adjusted * balance1Adjusted >= uint(_reserve0) * uint(_reserve1) * (1000**2),
                'UniswapV2: K'
            );
        }

        // 更新储备量
        _update(balance0, balance1, _reserve0, _reserve1);
        
        // 触发交换事件
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    // 函数：强制同步储备金到当前余额
    function sync() external lock {
        _update(
            IERC20(token0).balanceOf(address(this)),
            IERC20(token1).balanceOf(address(this)),
            reserve0,
            reserve1
        );
    }

    // 函数：强制将代币余额调整为储备金
    function skim(address to) external lock {
        address _token0 = token0;
        address _token1 = token1;
        _safeTransfer(_token0, to, IERC20(_token0).balanceOf(address(this)) - reserve0);
        _safeTransfer(_token1, to, IERC20(_token1).balanceOf(address(this)) - reserve1);
    }
}