// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Counter} from "../src/Counter.sol";
import {Owner} from "../src/Owner.sol";
import {MyERC20} from "../src/MyERC20.sol";

contract CheatcodeTest is Test {
    Counter public counter;
    address public alice;
    address public bob;

    function setUp() public {
        counter = new Counter();
        alice = makeAddr("alice");//生成固定地址 （每次测试相同）
        bob = makeAddr("bob");//生成固定地址 （每次测试相同）
    }

    // 测试用例1 （演示：区块号的变更）
    function test_Roll() public {
        counter.increment();
        assertEq(counter.number(), 1);

        uint256 newBlockNumber = 100;
        vm.roll(newBlockNumber);
        console.log("after roll Block number", block.number);

        assertEq(block.number, newBlockNumber);
        assertEq(counter.number(), 1);
    }

    //测试用例2：演示改变区块时间戳
    function test_Warp() public {
        uint256 newTimestamp = 1746669703; //
        vm.warp(newTimestamp);
        console.log("after warp Block timestamp", block.timestamp);
        assertEq(block.timestamp, newTimestamp);

        skip(1000);
        console.log("after skip Block timestamp", block.timestamp);
        assertEq(block.timestamp, newTimestamp + 1000);
    }

    //测试用例3：，更改下1个调用的发送者msg.sender,下一次交易的地址用alice这个地址
    function test_Prank() public {
        console.log("current contract address", address(this));

        Owner o = new Owner();
        console.log("owner address", address(o.owner()));
        assertEq(o.owner(), address(this));

        console.log("alice address", alice);
        vm.prank(alice);
        Owner o2 = new Owner();
        assertEq(o2.owner(), alice);
    }
    

    //测试用例4：vm.startPrank表示，对后续的语句都生效，直到stopPrank
    function test_StartPrank() public {
        console.log("current contract address", address(this));

        Owner o = new Owner();
        console.log("owner address", address(o.owner()));
        assertEq(o.owner(), address(this));

        vm.startPrank(alice);
        Owner o2 = new Owner();
        assertEq(o2.owner(), alice);
        assertEq(o2.owner(), alice);


        Owner o4 = new Owner();
        assertEq(o4.owner(), alice);

        vm.stopPrank();

        Owner o3 = new Owner();
        assertEq(o3.owner(), address(this));
    }

    //测试用例5：重置余额
    function test_Deal() public {
        vm.deal(alice, 100 ether);
        assertEq(alice.balance, 100 ether);

        vm.deal(alice, 1 ether); // Vm.deal
        assertEq(alice.balance, 1 ether);
    }
    
    //测试用例6：重置ERC20 的余额
    function test_Deal_ERC20() public {
        MyERC20 token = new MyERC20("OpenSpace S6", "OS6");
        console.log("token address", address(token));

        console.log("alice address", alice);

        deal(address(token), alice, 100 ether);  // StdCheats.deal

        console.log("alice token balance", token.balanceOf(alice));
        assertEq(token.balanceOf(alice), 100 ether);
    }

// forge test test/Cheatcode.t.sol --mt test_Revert_IFNOT_Owner -vv
//逆向测试，测试用例中包含对报错语句的预判，如果预判正确，则通过
    function test_Revert_IFNOT_Owner() public {
        
        vm.startPrank(alice);
        Owner o = new Owner();
        vm.stopPrank();

        vm.startPrank(bob);//后续所有调用将使用 bob 作为 msg.sender
        vm.expectRevert("Only the owner can transfer ownership"); // 预期下一条语句会revert
        o.transferOwnership(alice);//检查合约当前owner是alice，调用者是bob，会报错，所以预判正确
        vm.stopPrank();

    }

    function test_Revert_IFNOT_Owner2() public {
        vm.startPrank(alice);
        Owner o = new Owner();
        vm.stopPrank();

        vm.startPrank(bob);
        bytes memory data = abi.encodeWithSignature("NotOwner(address)", bob);
        vm.expectRevert(data); // 预期下一条语句会revert
        o.transferOwnership2(alice);
        vm.stopPrank();
    }

//用于测试事件触发，预期事件会触发，这是条件，满足了测试通过，不满足，测试不通过
    event OwnerTransfer(address indexed caller, address indexed newOwner);
    function test_Emit() public {
        Owner o = new Owner();
// function expectEmit(bool checkTopic1, bool checkTopic2, bool checkTopic3, bool checkData) external;
//期望检查第一个和第二个主题（indexed参数），但不检查第三个主题和事件数据（non-indexed参数）
        vm.expectEmit(true, true, false, false);//预期会触发事件
//显式地在当前上下文中（address(this)）触发OwnerTransfer事件，
        emit OwnerTransfer(address(this), bob);
//并指定新的合约所有者为bob。
        o.transferOwnership(bob);
    }
}