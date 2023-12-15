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
    address internal _operatorTeammate = address(5);

    address internal _toggle = address(333);
    address internal _eligibility = address(555);

    address[3] internal _shipOperators;
    address[3] internal _shipAddresses;
    uint256[3] internal _operatorHatIds;
    uint256[3] internal _shipHatIds;
    bytes[3] internal _shipTestData;

    uint256[3] internal _granteeHatId;
    address[3] internal _granteeAddresses;
    address[3] internal _granteeOperators;
    uint256[3] internal _granteeOperatorId;
    bytes[3] internal _granteeTestData;

    uint256 internal _topHatId;
    uint256 internal _facilitatorHatId;
    uint256 internal _registrarHatId;

    function setUp() public {
        _setupHats();
        _setupGrantShips();
        _setupSampleGrantees();
    }

    function _setupHats() internal {
        hats = new Hats("Test Name", "ipfs://");

        _topHatId = hats.mintTopHat(
            _topHatWearer,
            "testTopHat",
            "https://wwww/tophat.com/"
        );

        vm.prank(_topHatWearer);

        _facilitatorHatId = hats.createHat(
            _topHatId,
            "Facilitator Hat",
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

            _shipAddresses[i] = address(uint160(50 + i));

            vm.prank(_topHatWearer);
            hats.mintHat(_shipHatIds[i], _shipAddresses[i]);

            vm.prank(_shipAddresses[i]);
            _operatorHatIds[i] = hats.createHat(
                _shipHatIds[i],
                string.concat("Ship Operator Hat ", vm.toString(i + 1)),
                3,
                address(555),
                address(333),
                true,
                ""
            );

            _shipOperators[i] = address(uint160(10 + i));

            vm.prank(_topHatWearer);
            hats.mintHat(_operatorHatIds[i], _shipOperators[i]);

            unchecked {
                ++i;
            }
        }
    }

    function _setupGrantShips() internal {
        for (uint8 i = 0; i < 3; ) {
            _shipTestData[i] = abi.encode(
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
            _registrarHatId,
            _shipTestData
        );

        // deploy as expected

        vm.prank(_gameFacilitator);

        registry = new RequestRegistry(
            address(hats),
            _facilitatorHatId,
            _registrarHatId,
            _shipTestData
        );
    }

    function _setupSampleGrantees() internal {
        for (uint8 i = 0; i < 3; ) {
            vm.prank(_topHatWearer);
            _granteeHatId[i] = hats.createHat(
                _topHatId,
                string.concat("Sample Project Hat ", vm.toString(i + 1)),
                1,
                address(555),
                address(333),
                true,
                ""
            );
            _granteeOperators[i] = address(uint160(20 + i));
            _granteeAddresses[i] = address(uint160(30 + i));

            vm.prank(_topHatWearer);
            hats.mintHat(_granteeHatId[i], _granteeAddresses[i]);

            vm.prank(_granteeAddresses[i]);

            _granteeOperatorId[i] = hats.createHat(
                _granteeHatId[i],
                string.concat(
                    "Sample Project Operator Hat ",
                    vm.toString(i + 1)
                ),
                3,
                address(555),
                address(333),
                true,
                ""
            );

            _granteeTestData[i] = abi.encode(
                _granteeAddresses[i],
                _granteeOperatorId[i],
                3,
                string.concat(
                    "This is metadata for Grantee ",
                    vm.toString(i + 1)
                )
            );

            unchecked {
                ++i;
            }
        }
    }

    function testCreateRequest() public {
        //test to see if operator can create a request as expected.
        vm.prank(_shipOperators[0]);

        registry.createRequest(
            _shipHatIds[0],
            10000e18,
            2,
            '{"json": true}',
            _granteeHatId[0],
            _granteeTestData[0]
        );

        (
            uint256 shipHatId,
            uint256 operatorId,
            uint256 amountRequested,
            RequestRegistry.Status status,
            uint256 timestamp,
            RequestRegistry.Metadata memory Metadata,
            uint8 shipReviewScore,
            uint256 granteeHatId
        ) = registry.requests(0);

        assertEq(shipHatId, _shipHatIds[0]);
        assertEq(operatorId, _operatorHatIds[0]);
        assertEq(amountRequested, 10000e18);
        assertEq(uint256(status), uint256(RequestRegistry.Status.Pending));
        assertEq(timestamp, block.timestamp);
        assertEq(Metadata.metaType, 2);
        assertEq(Metadata.data, '{"json": true}');
        assertEq(shipReviewScore, 0);
        assertEq(granteeHatId, _granteeHatId[0]);

        // test to ensure that a request for a grantee that has not been
        // registered will create a grantee and store the data as expected

        // (
        //     address recipientAddress,
        //     uint256 granteeOperatorId,
        //     RequestRegistry.Metadata memory metadata
        // ) = registry.grantees(_granteeHatId[0]);

        // assertEq(recipientAddress, _granteeAddresses[0]);
        // assertEq(granteeOperatorId, _granteeOperatorId[0]);
        // assertEq(metadata.metaType, 3);
        // assertEq(metadata.data, "This is metadata for Grantee 1");
    }

    function _createDummyRequest(
        address _requester,
        uint256 _tokenAmtRequested,
        uint256 shipId
    ) internal {
        vm.prank(_requester);
        registry.createRequest(
            shipId,
            _tokenAmtRequested,
            2,
            '{"json": true}',
            _granteeHatId[0],
            _granteeTestData[0]
        );

        (, , uint256 amountRequested, , , , , ) = registry.requests(0);

        (, uint256 amountPending, , , ) = registry.ships(shipId);

        // Check that amounts recorded in Ship and Request both reflect the _tokenAmtRequested requested

        assertEq(amountPending, amountRequested);
        assertEq(amountRequested, _tokenAmtRequested);
        assertEq(amountPending, _tokenAmtRequested);
    }

    function testUnauthorizedCreateRequest() public {
        // test that request reverts as expected if caller does not hold an operator hat
        vm.expectRevert(RequestRegistry.NotAuthorized.selector);
        vm.prank(_nonWearer);
        registry.createRequest(
            _shipHatIds[0],
            10000e18,
            2,
            "",
            _granteeHatId[0],
            _granteeTestData[0]
        );

        // test that request reverts if an operator is wearing an operator hat for a
        // different ship
        vm.expectRevert(RequestRegistry.NotAuthorized.selector);
        vm.prank(_shipOperators[1]);
        registry.createRequest(
            _shipHatIds[0],
            10000e18,
            2,
            "",
            _granteeHatId[0],
            _granteeTestData[0]
        );

        // test to ensure that facilitators cannot create a request
        vm.expectRevert(RequestRegistry.NotAuthorized.selector);
        vm.prank(_gameFacilitator);
        registry.createRequest(
            _shipHatIds[0],
            10000e18,
            2,
            "",
            _granteeHatId[0],
            _granteeTestData[0]
        );
    }

    function testHatOfSameType() public {
        vm.prank(_topHatWearer);
        hats.mintHat(_operatorHatIds[0], _operatorTeammate);

        vm.prank(_operatorTeammate);
        registry.createRequest(
            _shipHatIds[0],
            10000e18,
            2,
            "",
            _granteeHatId[0],
            _granteeTestData[0]
        );

        vm.prank(_shipOperators[0]);
        registry.createRequest(
            _shipHatIds[0],
            10000e18,
            2,
            "",
            _granteeHatId[0],
            _granteeTestData[0]
        );
    }

    function testShipDoesNotExist() public {
        // test to ensure that a request cannot be created for a ship that does not exist
        vm.expectRevert(RequestRegistry.ShipDoesNotExist.selector);
        vm.prank(_shipOperators[0]);
        registry.createRequest(
            0,
            10000e18,
            2,
            "",
            _granteeHatId[0],
            _granteeTestData[0]
        );
    }

    function testSpendingCapExceeded() public {
        // test to ensure that a request cannot be created if the spending cap is exceeded
        vm.expectRevert(RequestRegistry.SpendingCapExceeded.selector);
        vm.prank(_shipOperators[0]);
        registry.createRequest(
            _shipHatIds[0],
            100000e18,
            2,
            "",
            _granteeHatId[0],
            _granteeTestData[0]
        );
    }

    function testApproveRequest() public {
        // test to ensure that a facilitator can approve a request
        uint256 shipId = _shipHatIds[0];
        uint256 TEN_THOUSAND_TOKENS = 10000e18;

        _createDummyRequest(_shipOperators[0], TEN_THOUSAND_TOKENS, shipId);

        vm.prank(_gameFacilitator);
        registry.approveRequest(0);

        (, , , RequestRegistry.Status approvedStatus, , , , ) = registry
            .requests(0);
        // Check that the status of the request is approved
        assertEq(
            uint256(approvedStatus),
            uint256(RequestRegistry.Status.Approved)
        );
    }

    function testRejectRequest() public {
        uint256 shipId = _shipHatIds[0];
        uint256 TEN_THOUSAND_TOKENS = 10000e18;

        _createDummyRequest(_shipOperators[0], TEN_THOUSAND_TOKENS, shipId);
        (, uint256 amountPending, , , ) = registry.ships(shipId);

        assertEq(amountPending, TEN_THOUSAND_TOKENS);

        vm.prank(_gameFacilitator);
        registry.rejectRequest(0);

        (, uint256 amountPendingAfterRejection, , , ) = registry.ships(shipId);

        // check that the amount pending has been removed
        assertEq(amountPendingAfterRejection, 0);

        (, , , RequestRegistry.Status rejectedStatus, , , , ) = registry
            .requests(0);

        assertEq(
            uint256(rejectedStatus),
            uint256(RequestRegistry.Status.Rejected)
        );

        // TEST WITH APPROVED REQUEST

        _createDummyRequest(_shipOperators[0], TEN_THOUSAND_TOKENS, shipId);

        vm.prank(_gameFacilitator);
        registry.approveRequest(1);

        vm.prank(_gameFacilitator);
        registry.rejectRequest(1);

        (, uint256 amountPendingAfterRejection2, , , ) = registry.ships(shipId);

        // check that the amount pending has been removed
        assertEq(amountPendingAfterRejection2, 0);

        (, , , RequestRegistry.Status rejectedStatus2, , , , ) = registry
            .requests(0);

        assertEq(
            uint256(rejectedStatus2),
            uint256(RequestRegistry.Status.Rejected)
        );
    }

    function testDistributeRequest() public {
        uint256 shipId = _shipHatIds[0];
        uint256 TEN_THOUSAND_TOKENS = 10000e18;

        _createDummyRequest(_shipOperators[0], TEN_THOUSAND_TOKENS, shipId);

        vm.prank(_gameFacilitator);
        registry.approveRequest(0);

        (, , , RequestRegistry.Status approvedStatus, , , , ) = registry
            .requests(0);

        assertEq(
            uint256(approvedStatus),
            uint256(RequestRegistry.Status.Approved)
        );

        (
            uint256 amountDistribtutedBeforeDistro,
            uint256 amountPendingBeforeDistro,
            ,
            ,

        ) = registry.ships(shipId);

        assertEq(amountDistribtutedBeforeDistro, 0);
        assertEq(amountPendingBeforeDistro, TEN_THOUSAND_TOKENS);

        vm.prank(_gameFacilitator);
        registry.distributeRequest(0);

        (
            uint256 amountDistribtutedAfterDistro,
            uint256 amountPendingAfterDistro,
            ,
            ,

        ) = registry.ships(shipId);

        assertEq(amountDistribtutedAfterDistro, TEN_THOUSAND_TOKENS);
        assertEq(amountPendingAfterDistro, 0);

        (, , , RequestRegistry.Status distributedStatus, , , , ) = registry
            .requests(0);

        assertEq(
            uint256(distributedStatus),
            uint256(RequestRegistry.Status.Distributed)
        );
    }

    function testCancelRequest() public {
        uint256 shipId = _shipHatIds[0];
        uint256 TEN_THOUSAND_TOKENS = 10000e18;

        _createDummyRequest(_shipOperators[0], TEN_THOUSAND_TOKENS, shipId);

        (, uint256 amountPending, , , ) = registry.ships(shipId);

        assertEq(amountPending, TEN_THOUSAND_TOKENS);

        vm.prank(_shipOperators[0]);
        registry.cancelRequest(0);

        (, uint256 amountPendingAfterCancel, , , ) = registry.ships(shipId);

        assertEq(amountPendingAfterCancel, 0);

        (, , , RequestRegistry.Status cancelledStatus, , , , ) = registry
            .requests(0);

        assertEq(
            uint256(cancelledStatus),
            uint256(RequestRegistry.Status.Cancelled)
        );

        // TEST WITH APPROVED REQUEST

        _createDummyRequest(_shipOperators[0], TEN_THOUSAND_TOKENS, shipId);

        vm.prank(_gameFacilitator);
        registry.approveRequest(1);

        (, , , RequestRegistry.Status approvedStatus, , , , ) = registry
            .requests(1);

        assertEq(
            uint256(approvedStatus),
            uint256(RequestRegistry.Status.Approved)
        );

        vm.prank(_shipOperators[0]);
        registry.cancelRequest(1);

        (, uint256 amountPendingAfterCancel2, , , ) = registry.ships(shipId);

        assertEq(amountPendingAfterCancel2, 0);

        (, , , RequestRegistry.Status cancelledStatus2, , , , ) = registry
            .requests(1);

        assertEq(
            uint256(cancelledStatus2),
            uint256(RequestRegistry.Status.Cancelled)
        );
    }

    function testNonFacilitatorApproveRequest() public {
        // test to ensure non-hatwearer cannot approve a request
        vm.expectRevert(RequestRegistry.NotAuthorized.selector);
        vm.prank(_nonWearer);
        registry.approveRequest(0);

        vm.expectRevert(RequestRegistry.NotAuthorized.selector);
        vm.prank(_shipOperators[0]);
        registry.approveRequest(0);
    }

    function testNonFacilitatorRejectRequest() public {
        // test to ensure that only facilitators can reject a request
        vm.expectRevert(RequestRegistry.NotAuthorized.selector);
        vm.prank(_nonWearer);
        registry.rejectRequest(0);

        vm.expectRevert(RequestRegistry.NotAuthorized.selector);
        vm.prank(_shipOperators[0]);
        registry.rejectRequest(0);
    }

    function testNonFacilitatorDistributeRequest() public {
        // test to ensure that only facilitators can distribute a request
        vm.expectRevert(RequestRegistry.NotAuthorized.selector);
        vm.prank(_nonWearer);
        registry.distributeRequest(0);

        vm.expectRevert(RequestRegistry.NotAuthorized.selector);
        vm.prank(_shipOperators[0]);
        registry.distributeRequest(0);
    }

    function testNonShipOperatorCancelRequest() public {
        uint256 shipId = _shipHatIds[0];
        uint256 TEN_THOUSAND_TOKENS = 10000e18;

        _createDummyRequest(_shipOperators[0], TEN_THOUSAND_TOKENS, shipId);

        // non-weaer cannot cancel request
        vm.expectRevert(RequestRegistry.NotAuthorized.selector);
        vm.prank(_nonWearer);
        registry.cancelRequest(0);

        // facilitator cannot cancel request
        vm.expectRevert(RequestRegistry.NotAuthorized.selector);
        vm.prank(_gameFacilitator);
        registry.cancelRequest(0);

        // operator cannot cancel request for a different ship
        vm.expectRevert(RequestRegistry.NotAuthorized.selector);
        vm.prank(_shipOperators[1]);
        registry.cancelRequest(0);

        // operator can cancel request
        vm.prank(_shipOperators[0]);
        registry.cancelRequest(0);

        (, , , RequestRegistry.Status cancelledStatus, , , , ) = registry
            .requests(0);

        assertEq(
            uint256(cancelledStatus),
            uint256(RequestRegistry.Status.Cancelled)
        );
    }

    function testRequestDoesNotExist() public {
        // Approve
        vm.expectRevert(RequestRegistry.RequestDoesNotExist.selector);
        vm.prank(_gameFacilitator);

        registry.approveRequest(0);

        // Reject
        vm.expectRevert(RequestRegistry.RequestDoesNotExist.selector);
        vm.prank(_gameFacilitator);

        registry.rejectRequest(0);

        // Distribute
        vm.expectRevert(RequestRegistry.RequestDoesNotExist.selector);
        vm.prank(_gameFacilitator);
        registry.distributeRequest(0);

        // Cancel
        vm.expectRevert(RequestRegistry.RequestDoesNotExist.selector);
        vm.prank(_shipOperators[0]);
        registry.cancelRequest(0);
    }

    function testRejectIncorrectStatus() public {
        uint256 shipId = _shipHatIds[0];
        uint256 TEN_THOUSAND_TOKENS = 10000e18;

        _createDummyRequest(_shipOperators[0], TEN_THOUSAND_TOKENS, shipId);

        vm.prank(_gameFacilitator);
        registry.rejectRequest(0);

        vm.expectRevert(RequestRegistry.IncorrectRequestStatus.selector);
        vm.prank(_gameFacilitator);
        registry.rejectRequest(0);

        vm.expectRevert(RequestRegistry.IncorrectRequestStatus.selector);
        vm.prank(_gameFacilitator);
        registry.approveRequest(0);

        vm.expectRevert(RequestRegistry.IncorrectRequestStatus.selector);
        vm.prank(_gameFacilitator);
        registry.distributeRequest(0);

        vm.expectRevert(RequestRegistry.IncorrectRequestStatus.selector);
        vm.prank(_shipOperators[0]);
        registry.cancelRequest(0);
    }

    function testApproveIncorrectStatus() public {
        uint256 shipId = _shipHatIds[0];
        uint256 TEN_THOUSAND_TOKENS = 10000e18;

        _createDummyRequest(_shipOperators[0], TEN_THOUSAND_TOKENS, shipId);

        vm.prank(_gameFacilitator);
        registry.approveRequest(0);

        vm.expectRevert(RequestRegistry.IncorrectRequestStatus.selector);
        vm.prank(_gameFacilitator);
        registry.approveRequest(0);

        // Approved requests can be rejected, distributed, or cancelled
    }

    function testDistributeIncorrectStatus() public {
        uint256 shipId = _shipHatIds[0];
        uint256 TEN_THOUSAND_TOKENS = 10000e18;

        _createDummyRequest(_shipOperators[0], TEN_THOUSAND_TOKENS, shipId);

        vm.prank(_gameFacilitator);
        registry.approveRequest(0);

        vm.prank(_gameFacilitator);
        registry.distributeRequest(0);

        vm.expectRevert(RequestRegistry.IncorrectRequestStatus.selector);
        vm.prank(_gameFacilitator);
        registry.distributeRequest(0);

        vm.expectRevert(RequestRegistry.IncorrectRequestStatus.selector);
        vm.prank(_gameFacilitator);
        registry.approveRequest(0);

        vm.expectRevert(RequestRegistry.IncorrectRequestStatus.selector);
        vm.prank(_gameFacilitator);
        registry.rejectRequest(0);

        vm.expectRevert(RequestRegistry.IncorrectRequestStatus.selector);
        vm.prank(_shipOperators[0]);
        registry.cancelRequest(0);
    }

    function testCancelledIncorrectStatus() public {
        uint256 shipId = _shipHatIds[0];
        uint256 TEN_THOUSAND_TOKENS = 10000e18;
        _createDummyRequest(_shipOperators[0], TEN_THOUSAND_TOKENS, shipId);

        vm.prank(_shipOperators[0]);
        registry.cancelRequest(0);

        vm.expectRevert(RequestRegistry.IncorrectRequestStatus.selector);
        vm.prank(_shipOperators[0]);
        registry.cancelRequest(0);

        vm.expectRevert(RequestRegistry.IncorrectRequestStatus.selector);
        vm.prank(_gameFacilitator);
        registry.approveRequest(0);

        vm.expectRevert(RequestRegistry.IncorrectRequestStatus.selector);
        vm.prank(_gameFacilitator);
        registry.rejectRequest(0);

        vm.expectRevert(RequestRegistry.IncorrectRequestStatus.selector);
        vm.prank(_gameFacilitator);
        registry.distributeRequest(0);
    }
}
