// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Counter {
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
        address shipAddress; // who
        uint256 amount; // what
        Status requestStatus; // where
        uint256 timestamp; // when
        Metadata metadata; // why
    }

    // State

    mapping(uint256 => Request) public requests;

    // Events

    // Errors

    error RequestAlreadyExists();

    event RequestCreated(
        uint256 indexed requestId,
        address indexed shipHatId,
        uint256 amount,
        uint256 timestamp,
        uint32 metaType,
        string data
    );

    event RequestStatusChanged(
        uint256 indexed requestId,
        Status indexed requestStatus
    );

    // MODIFIERS
    // FUNCTIONS

    function createRequest(
        uint256 requestId,
        address shipAddress,
        uint256 amount,
        uint32 metaType,
        string memory data
    ) public {
        if(
            requests[requestId].timestamp == 0)
            revert "Request already exists"


        requests[requestId] = Request({
            shipAddress: shipAddress,
            amount: amount,
            requestStatus: Status.Pending,
            timestamp: block.timestamp,
            metadata: Metadata({metaType: metaType, data: data})
        });

        emit RequestCreated(
            requestId,
            shipAddress,
            amount,
            block.timestamp,
            metaType,
            data
        );
    }
}
