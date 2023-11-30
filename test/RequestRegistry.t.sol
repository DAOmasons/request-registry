// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {RequestRegistry} from "../src/RequestRegistry.sol";
import {Hats} from "hats-protocol/Hats.sol";

import "forge-std/console.sol";

contract RegistryTest is Test {
    RequestRegistry public registry;
    Hats public hats;

    address internal _gameFacilitator = address(2);
    address internal _nonWearer = address(3);
    address internal _topHatWearer = address(4);

    address internal _toggle = address(333);
    address internal _eligibility = address(555);

    address[3] internal _shipOperators;
    uint256[3] internal _operatorHatIds;
    uint256[3] internal _shipHatIds;

    uint256 internal _topHatId;
    uint256 internal _facilitatorHatId;

    function setUp() public {
        _setupHats();
        _setupGrantShips();
    }

    function _setupHats() internal {
        bool logHats = false;
        hats = new Hats("Test Name", "ipfs://");

        _topHatId = hats.mintTopHat(
            _topHatWearer,
            "testTopHat",
            "https://wwww/tophat.com/"
        );

        vm.prank(_topHatWearer);

        _facilitatorHatId = hats.createHat(
            _topHatId,
            "Child Hat 1",
            2,
            _eligibility,
            _toggle,
            true,
            ""
        );

        vm.prank(_topHatWearer);
        hats.mintHat(_facilitatorHatId, _gameFacilitator);

        for (uint32 i = 0; i < 3; ) {
            vm.prank(_topHatWearer);
            _shipHatIds[i] = hats.createHat(
                _topHatId,
                string.concat("Ship Hat ", vm.toString(i + 1)),
                1,
                _eligibility,
                _toggle,
                true,
                ""
            );
            if (logHats) {
                console.log("Ship Operator ID:");
                console.log(_shipHatIds[i]);
            }

            vm.prank(_topHatWearer);
            _operatorHatIds[i] = hats.createHat(
                _topHatId,
                string.concat("Ship Operator Hat", vm.toString(i + 1)),
                1,
                address(555),
                address(333),
                true,
                ""
            );
            if (logHats) {
                console.log("Operator ID");
                console.log(_operatorHatIds[i]);
            }

            _shipOperators[i] = address(uint160(10 + i));

            if (logHats) {
                console.log("Operator Address");
                console.log(_shipOperators[i]);
            }

            vm.prank(_topHatWearer);
            hats.mintHat(_operatorHatIds[i], _shipOperators[i]);

            unchecked {
                ++i;
            }
        }
    }

    function _setupGrantShips() internal {
        bytes[3] memory shipConfigs;

        for (uint8 i = 0; i < 3; ) {
            shipConfigs[i] = abi.encode(
                30000e18,
                _operatorHatIds[i],
                _shipHatIds[i],
                2,
                string.concat("This is metadata for Ship ", vm.toString(i))
            );

            unchecked {
                ++i;
            }
        }

        // Test to ensure that only facilitators can create the contract
        vm.expectRevert(RequestRegistry.NotAuthorized.selector);
        vm.prank(_nonWearer);
        registry = new RequestRegistry(
            address(hats),
            _facilitatorHatId,
            shipConfigs
        );

        // deploy as expected

        vm.prank(_gameFacilitator);

        registry = new RequestRegistry(
            address(hats),
            _facilitatorHatId,
            shipConfigs
        );
    }

    function createRequest() public {
        //test to see if operator can create a request as expected.
        vm.prank(_shipOperators[0]);
        registry.createRequest(_shipHatIds[0], 10000e18, 2, "");
    }

    function testUnauthorizedCreateRequest() public {
        // test that request reverts as expected if caller does not hold an operator hat
        vm.expectRevert(RequestRegistry.NotAuthorized.selector);
        vm.prank(_nonWearer);
        registry.createRequest(_shipHatIds[0], 10000e18, 2, "");

        // test that request reverts if an operator is wearing an operator hat for a
        // different ship
        vm.expectRevert(RequestRegistry.NotAuthorized.selector);
        vm.prank(_shipOperators[1]);
        registry.createRequest(_shipHatIds[0], 10000e18, 2, "");

        // test to ensure that facilitators cannot create a request
        vm.expectRevert(RequestRegistry.NotAuthorized.selector);
        vm.prank(_gameFacilitator);
        registry.createRequest(_shipHatIds[0], 10000e18, 2, "");
    }

    function testFuzz_SetNumber(uint256 x) public {
        // counter.setNumber(x);
        // assertEq(counter.number(), x);
    }
}
