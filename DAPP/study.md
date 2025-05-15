forge script  script/deploy_tokenBankV3.s.sol --rpc-url local --broadcast --private-key  0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80  
![1747104701226](image/study/1747104701226.png)



# 前后端联合工作 5月14日作业
任务如下：
1.需要帮我做1个后端，用nestjs框架，目录为：D:\blockchain\DAPP\tokenbank_backend
我计算机现有node的版本如下：v20.17.0
2.后端需要索引出Token 转账信息，记录到数据库中：
- D:\blockchain\DAPP\tokenbank_frontdend 这个目录下是之前做的前端，使用vue框架。这个前端可以将metamask钱包中的token存款到tokenbank，也可以从tokenbank取款；
- token合约和tokenbank合约是部署在sepolia测试中的，
- 现在需要将token转账的信息从区块链中读取出来，要求能够实时读取，并同步记录到数据库中，
- 前端增加转账token功能，可以连接钱包后，将token转给任意钱包
- 前端通过Restful 接口来查询转账记录，前端界面增加查询功能，可以通过输入钱包用户的地址，查询其转入和转出token的记录；
- 数据库连接信息：IP:192.168.0.111  用户名：zhf   密码：123123  端口：5432  数据库名：zhf_db   数据库类型及版本：psql (PostgreSQL) 14.4
-  数据库需要建表，请提供给我建表语句；
-  以下是token合约转账的函数：
  
 event Transfer(address indexed from, address indexed to, uint256 value);

 function transfer(address _to, uint256 _value) public returns (bool success) {
        // write your code here
        require(_to != address(0),'Invalid Address');//检查接收地址，若0，则报错并回滚交易
        require(balances[msg.sender] >= _value,'ERC20: transfer amount exceeds balance');//检查调用该函数得账户地址的余额，若不足,则报错并回滚交易
        balances[msg.sender] -= _value;
        balances[_to] += _value;

        emit Transfer(msg.sender, _to, _value);  
        return true;   
    }

- 能用viem库实现的，就用viem库去实现。viem库已经安装。


 npx prettier --write "src/**/*.{js,ts}"

 npm run start:dev

帮我写个前端，目录我已经创建了，你不要创建了,目录是D:\blockchain\DAPP\query_frontend
用vue3去完成，简单直观就可以了
1.我已经做1个后端，用的nestjs框架，目录为：D:\blockchain\DAPP\query_backend
后端是将区块链上token转账信息记录到数据库中，并提供Restful接口查询转账记录。
2. 我计算机现有node的版本如下：v20.17.0
任务要求：
- 前端可以连接钱包
- 前端通过Restful 接口来查询转账记录，前端界面增加查询功能，可以通过输入钱包用户的地址，查询其转入和转出token的记录；
- 可 查询指定交易哈希的转账记录；对应的接口后端已经提供，需要你扫描后端文件确认。
- 分页查询所有转账记录；对应的接口后端已经提供，需要你扫描后端文件确认。

帮我写个前端，目录是D:\blockchain\DAPP\query_frontend
用vue3去完成，简单直观就可以了
1.我已经做1个后端，用的nestjs框架，目录为：D:\blockchain\DAPP\query_backend
后端是将区块链上token转账信息记录到数据库中，并提供Restful接口查询转账记录。
1. 我计算机现有node的版本如下：v20.17.0
任务要求：
- 前端可以连接钱包
- 前端通过Restful 接口来查询转账记录，前端界面增加查询功能，可以通过输入钱包用户的地址，查询其转入和转出token的记录；
- 可 查询指定交易哈希的转账记录；对应的接口后端已经提供，需要你扫描后端文件确认。
- 分页查询所有转账记录；对应的接口后端已经提供，需要你扫描后端文件确认。

![1747327426600](image/study/1747327426600.png)