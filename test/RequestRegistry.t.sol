// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {RequestRegistry} from "../src/RequestRegistry.sol";
import {Hats} from "hats-protocol/Hats.sol";

import "forge-std/console.sol";

contract RegistryTest is Test {
    RequestRegistry public registry;
    Hats hats;

    address internal shipOperator = address(1);
    address internal gamefacilitator = address(2);
    address internal nonWearer = address(3);
    address internal topHatWearer = address(4);

    address internal toggle = address(333);
    address internal eligibility = address(555);

    uint256 internal shipOperatorId;
    uint256 internal shipHatId;
    uint256 internal topHatId;
    uint256 internal facilitatorHatId;

    function setUp() public {
        _setupHats();
    }

    function _setupHats() internal {
        hats = new Hats("Test Name", "ipfs://");

        topHatId = hats.mintTopHat(
            topHatWearer,
            "testTopHat",
            "https://wwww/tophat.com/"
        );

        vm.prank(topHatWearer);

        facilitatorHatId = hats.createHat(
            topHatId,
            "Child Hat 1",
            2,
            eligibility,
            toggle,
            true,
            ""
        );

        vm.prank(topHatWearer);
        hats.mintHat(facilitatorHatId, gamefacilitator);

        vm.prank(topHatWearer);

        shipHatId = hats.createHat(
            topHatId,
            "Ship Hat 1",
            1,
            eligibility,
            toggle,
            true,
            ""
        );

        vm.prank(topHatWearer);

        shipOperatorId = hats.createHat(
            topHatId,
            "Ship Operator 1",
            1,
            address(555),
            address(333),
            true,
            ""
        );

        vm.prank(topHatWearer);
        hats.mintHat(shipOperatorId, shipOperator);
    }

    function test_Increment() public {
        console.log(2);
        // counter.increment();
        // assertEq(counter.number(), 1);
    }

    function testFuzz_SetNumber(uint256 x) public {
        // counter.setNumber(x);
        // assertEq(counter.number(), x);
    }
}
