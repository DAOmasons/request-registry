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
        Status requestStatus;
        uint256 timestamp;
        Metadata metadata;
    }

    struct Ship {
        uint256 amountDistributed;
        uint256 totalDistrubtion;
        uint256 operatorHatId;
    }

    // State

    IHats hats;
    uint256 private nonce;
    // maps nonce to request
    mapping(uint256 => Request) public requests;
    // maps grant ship branch ID to ship
    mapping(uint256 => Ship) public ships;

    // Events

    // Errors

    error NotAuthorizedToRequest();
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

    event RequestStatusChanged(
        uint256 indexed requestId,
        Status indexed requestStatus
    );

    // MODIFIERS
    // FUNCTIONS

    constructor(address _hatsAddress) {
        hats = IHats(_hatsAddress);

        // create ships and set operator hat
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

        if (hats.isWearerOfHat(msg.sender, ship.operatorHatId))
            revert NotAuthorizedToRequest();

        // check if allocation amount is greater than the ships available allocation
        if (ship.amountDistributed + _amountRequested > ship.totalDistrubtion)
            revert SpendingCapExceeded();

        requests[nonce] = Request({
            shipHatId: _shipHatId,
            operatorId: _operatorId,
            amountRequested: _amountRequested,
            requestStatus: Status.Pending,
            timestamp: block.timestamp,
            metadata: Metadata({metaType: _metaType, data: _metadata})
        });

        nonce++;

        emit RequestCreated(
            nonce,
            _shipHatId,
            _operatorId,
            _amountRequested,
            block.timestamp,
            _metaType,
            _metadata
        );
    }
}
