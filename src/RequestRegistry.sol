// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Hats} from "hats-protocol/Hats.sol";
import {IHats} from "hats-protocol/Interfaces/IHats.sol";

contract RequestRegistry {
    // STATUS

    enum Status {
        Pending,
        Rejected,
        Approved,
        Distributed
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
    error ShipDoesntExist();
    error SpendingCapExceeded();

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

    event RequestStatusChanged(uint256 indexed requestId, Status indexed status);

    event GrantShipsDeployed(address hatsTree, uint256 facilitatorHatId);

    // MODIFIERS
    // FUNCTIONS

    constructor(address _hatsAddress, uint256 _facilitatorHatId, bytes[3] memory _shipsData) {
        hats = IHats(_hatsAddress);
        facilitatorHatId = _facilitatorHatId;

        if (!hats.isWearerOfHat(msg.sender, facilitatorHatId)) {
            revert NotAuthorized();
        }

        for (uint32 i = 0; i < _shipsData.length;) {
            (
                uint256 _totalDistribution,
                uint256 _operatorHatId,
                uint256 _shipHatId,
                uint32 _metaType,
                string memory _metadata
            ) = abi.decode(_shipsData[i], (uint256, uint256, uint256, uint32, string));

            ships[_shipHatId] = Ship({
                amountDistributed: 0,
                amountPending: 0,
                totalDistribution: _totalDistribution,
                operatorHatId: _operatorHatId,
                metadata: Metadata({metaType: _metaType, data: _metadata})
            });

            emit ShipDeployed(_shipHatId, _operatorHatId, _totalDistribution, _metaType, _metadata, block.timestamp);

            unchecked {
                ++i;
            }
        }
        emit GrantShipsDeployed(_hatsAddress, _facilitatorHatId);
    }

    function createRequest(
        uint256 _shipHatId,
        // derive operator Id from ship Id?
        uint256 _operatorId,
        uint256 _amountRequested,
        uint32 _metaType,
        string memory _metadata
    ) public {
        if (ships[_shipHatId].operatorHatId == 0) revert ShipDoesntExist();

        Ship storage ship = ships[_shipHatId];

        if (hats.isWearerOfHat(msg.sender, ship.operatorHatId)) {
            revert NotAuthorized();
        }

        // check if allocation amount is greater than the ships available allocation
        if (ship.amountDistributed + ship.amountPending + _amountRequested > ship.totalDistribution) {
            revert SpendingCapExceeded();
        }

        requests[nonce] = Request({
            shipHatId: _shipHatId,
            operatorId: _operatorId,
            amountRequested: _amountRequested,
            status: Status.Pending,
            timestamp: block.timestamp,
            metadata: Metadata({metaType: _metaType, data: _metadata})
        });

        ship.amountPending = _amountRequested + ship.amountPending;

        unchecked {
            ++nonce;
        }

        emit RequestCreated(nonce, _shipHatId, _operatorId, _amountRequested, block.timestamp, _metaType, _metadata);
    }

    function changeRequestStatus(uint256 _requestId, Status _status) public {
        if (!hats.isWearerOfHat(msg.sender, facilitatorHatId)) {
            revert NotAuthorized();
        }
        Request storage request = requests[_requestId];
        request.status = _status;
        emit RequestStatusChanged(_requestId, _status);
    }
}
