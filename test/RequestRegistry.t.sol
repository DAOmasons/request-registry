// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {RequestRegistry} from "../src/RequestRegistry.sol";
import {Hats} from "hats-protocol/Hats.sol";

contract RegistryTest is Test {
    RequestRegistry public registry;
    Hats hats;
    

    address internal shipOperator = address(1);
    address internal gamefacilitator = address(2);
    address internal nonWearer = address(3);

    uint256 interal operatorRole;
    uint256 interal facilitatorHatId; 
    


    function setUp() public {
        hats = new Hats("Test Name", "ipfs://");

        
    }

    function test_Increment() public {
        // counter.increment();
        // assertEq(counter.number(), 1);
    }

    function testFuzz_SetNumber(uint256 x) public {
        // counter.setNumber(x);
        // assertEq(counter.number(), x);
    }
}
