// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Hats} from "hats-protocol/Hats.sol";
import {IHats} from "hats-protocol/Interfaces/IHats.sol";

import "forge-std/console.sol";

contract RequestRegistry {
    // STATUS

    enum Status {
        Pending,
        Rejected,
        Approved,
        Distributed,
        Cancelled
    }

    // Metatype
    // 0 - IPFS
    // 1 - URL
    // 2 - JSON
    // 3 - Arweave
    struct Metadata {
        uint32 metaType;
        string data;
    }

    // STRUCTS

    struct Request {
        uint256 shipHatId;
        uint256 operatorId;
        uint256 amountRequested;
        Status status;
        uint256 timestamp;
        Metadata metadata;
    }

    struct Ship {
        uint256 amountDistributed;
        uint256 amountPending;
        uint256 totalDistribution;
        uint256 operatorHatId;
        Metadata metadata;
    }

    // State

    IHats hats;

    uint256 facilitatorHatId;

    uint256 private nonce;

    // maps nonce to request
    mapping(uint256 => Request) public requests;
    // maps grant ship branch ID to ship
    mapping(uint256 => Ship) public ships;

    // Events

    // Errors

    error NotAuthorized();
    error ShipDoesNotExist();
    error SpendingCapExceeded();
    error IncorrectRequestStatus();

    modifier onlyFacilitator() {
        if (!hats.isWearerOfHat(msg.sender, facilitatorHatId)) {
            revert NotAuthorized();
        }
        _;
    }

    // Events

    event RequestCreated(
        uint256 indexed requestId,
        uint256 indexed shipHatId,
        uint256 operatorId,
        uint256 amountRequested,
        uint256 timestamp,
        uint32 metaType,
        string metadata
    );

    event ShipDeployed(
        uint256 shipId,
        uint256 operatorHatId,
        uint256 totalDistribution,
        uint32 metatype,
        string metadata,
        uint256 timestamp
    );

    event RequestStatusChanged(
        uint256 indexed requestId,
        Status indexed status
    );

    event GrantShipsDeployed(address hatsTree, uint256 facilitatorHatId);

    // MODIFIERS
    // FUNCTIONS

    constructor(
        address _hatsAddress,
        uint256 _facilitatorHatId,
        bytes[3] memory _shipsData
    ) {
        hats = IHats(_hatsAddress);
        facilitatorHatId = _facilitatorHatId;

        if (!hats.isWearerOfHat(msg.sender, facilitatorHatId)) {
            revert NotAuthorized();
        }

        for (uint32 i = 0; i < _shipsData.length; ) {
            (
                uint256 _totalDistribution,
                uint256 _operatorHatId,
                uint256 _shipHatId,
                uint32 _metaType,
                string memory _metadata
            ) = abi.decode(
                    _shipsData[i],
                    (uint256, uint256, uint256, uint32, string)
                );

            ships[_shipHatId] = Ship({
                amountDistributed: 0,
                amountPending: 0,
                totalDistribution: _totalDistribution,
                operatorHatId: _operatorHatId,
                metadata: Metadata({metaType: _metaType, data: _metadata})
            });

            emit ShipDeployed(
                _shipHatId,
                _operatorHatId,
                _totalDistribution,
                _metaType,
                _metadata,
                block.timestamp
            );

            unchecked {
                ++i;
            }
        }
        emit GrantShipsDeployed(_hatsAddress, _facilitatorHatId);
    }

    function createRequest(
        uint256 _shipHatId,
        uint256 _amountRequested,
        uint32 _metaType,
        string memory _metadata
    ) public {
        Ship storage ship = ships[_shipHatId];

        if (ship.operatorHatId == 0) revert ShipDoesNotExist();

        if (!hats.isWearerOfHat(msg.sender, ship.operatorHatId)) {
            revert NotAuthorized();
        }

        // check if allocation amount is greater than the ships available allocation
        if (
            ship.amountDistributed + ship.amountPending + _amountRequested >
            ship.totalDistribution
        ) {
            revert SpendingCapExceeded();
        }

        requests[nonce] = Request({
            shipHatId: _shipHatId,
            operatorId: ship.operatorHatId,
            amountRequested: _amountRequested,
            status: Status.Pending,
            timestamp: block.timestamp,
            metadata: Metadata({metaType: _metaType, data: _metadata})
        });

        ship.amountPending = _amountRequested + ship.amountPending;

        emit RequestCreated(
            nonce,
            _shipHatId,
            ship.operatorHatId,
            _amountRequested,
            block.timestamp,
            _metaType,
            _metadata
        );

        unchecked {
            ++nonce;
        }
    }

    function rejectRequest(uint256 _requestId) public onlyFacilitator {
        Request storage request = requests[_requestId];

        if (
            request.status != Status.Pending &&
            request.status != Status.Approved
        ) revert IncorrectRequestStatus();

        request.status = Status.Rejected;
        Ship storage ship = ships[request.shipHatId];
        ship.amountPending = ship.amountPending - request.amountRequested;

        // write event
        emit RequestStatusChanged(_requestId, Status.Rejected);
    }

    function approveRequest(uint256 _requestId) public onlyFacilitator {
        Request storage request = requests[_requestId];

        if (request.status != Status.Pending) revert IncorrectRequestStatus();

        request.status = Status.Approved;

        // write event
        emit RequestStatusChanged(_requestId, Status.Approved);
    }

    function distributeRequest(uint256 _requestId) public onlyFacilitator {
        Request storage request = requests[_requestId];

        if (request.status != Status.Approved) revert IncorrectRequestStatus();

        request.status = Status.Distributed;

        Ship storage ship = ships[request.shipHatId];
        ship.amountPending = ship.amountPending - request.amountRequested;
        ship.amountDistributed =
            ship.amountDistributed +
            request.amountRequested;

        // write event
        emit RequestStatusChanged(_requestId, Status.Distributed);
    }

    function cancelRequest(uint256 _requestId) public {
        Request storage request = requests[_requestId];

        if (
            request.status != Status.Pending &&
            request.status != Status.Approved
        ) revert IncorrectRequestStatus();

        if (!hats.isWearerOfHat(msg.sender, request.operatorId))
            revert NotAuthorized();

        request.status = Status.Cancelled;
        Ship storage ship = ships[request.shipHatId];
        ship.amountPending = ship.amountPending - request.amountRequested;
        // write event
        emit RequestStatusChanged(_requestId, Status.Cancelled);
    }

    // function getShip(uint _shipHatId) public view returns (Ship memory ship) {
    //     return ships[_shipHatId];
    // }

    // function getFundingAvailable(
    //     uint _shipHatId
    // ) public view returns (uint256 fundsRemaining) {
    //     Ship memory ship = getShip(_shipHatId);

    //     return (ship.totalDistribution -
    //         ship.amountPending -
    //         ship.amountDistributed);
    // }
}
