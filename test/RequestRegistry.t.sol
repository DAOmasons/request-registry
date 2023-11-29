// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {RequestRegistry} from "../src/RequestRegistry.sol";
import {Hats} from "hats-protocol/Hats.sol";

import "forge-std/console.sol";

contract RegistryTest is Test {
    RequestRegistry public registry;
    Hats hats;

    address internal gamefacilitator = address(2);
    address internal nonWearer = address(3);
    address internal topHatWearer = address(4);

    address internal toggle = address(333);
    address internal eligibility = address(555);

    address[3] internal shipOperators;
    uint256[3] internal operatorHatIds;
    uint256[3] internal shipHatIds;
    uint256 internal topHatId;
    uint256 internal facilitatorHatId;

    function setUp() public {
        _setupHats();
        _setupGrantShips();
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

        for (uint32 i = 0; i < 3; ) {
            vm.prank(topHatWearer);
            shipHatIds[i] = hats.createHat(
                topHatId,
                string.concat("Ship Hat ", vm.toString(i + 1)),
                1,
                eligibility,
                toggle,
                true,
                ""
            );

            console.log("Ship Operator ID:");
            console.log(shipHatIds[i]);

            vm.prank(topHatWearer);
            operatorHatIds[i] = hats.createHat(
                topHatId,
                string.concat("Ship Operator Hat", vm.toString(i + 1)),
                1,
                address(555),
                address(333),
                true,
                ""
            );

            console.log("Operator ID");
            console.log(operatorHatIds[i]);

            shipOperators[i] = address(uint160(10 + i));

            console.log("Operator Address");
            console.log(shipOperators[i]);

            vm.prank(topHatWearer);
            hats.mintHat(operatorHatIds[i], shipOperators[i]);

            unchecked {
                ++i;
            }
        }
    }

    function _setupGrantShips() internal {
        bytes[3] memory shipConfigs;

        for (uint8 i = 0; i < 3; ) {
            shipConfigs[i] = abi.encode(
                20000e18,
                operatorHatIds[i],
                shipHatIds[i],
                2,
                string.concat("This is metadata for Ship ", vm.toString(i))
            );

            unchecked {
                ++i;
            }
        }

        vm.prank(gamefacilitator);

        registry = new RequestRegistry(
            address(hats),
            facilitatorHatId,
            shipConfigs
        );
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
