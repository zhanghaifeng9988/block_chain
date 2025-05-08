// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import '../lib/forge-std/src/console.sol';

contract Counter {
    uint256 public number;

    function setNumber(uint256 newNumber) public {
        number = newNumber;
        console.log("New number is: ", number);
    }

    function increment() public {
        number++;
        console.log("Incremented the number to: ", number);
    }
}
