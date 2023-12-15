// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Hats} from "hats-protocol/Hats.sol";
import {IHats} from "hats-protocol/Interfaces/IHats.sol";

import "forge-std/console.sol";

contract RequestRegistry {
    // STATUS

    enum Status {
        // Todo - add a default or 'none' status
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
        // Todo - probably don't neet a timestamp
        uint256 timestamp;
        // Todo -  If we have grantees now, do we still need to store the metadata?
        Metadata metadata;
        uint8 shipReviewScore;
        uint256 granteeHatId;
    }

    struct Ship {
        uint256 amountDistributed;
        uint256 amountPending;
        uint256 totalDistribution;
        uint256 operatorHatId;
        Metadata metadata;
    }

    struct Grantee {
        address recipientAddress;
        uint256 granteeOperatorId;
        bool verified;
        Metadata metadata;
    }

    // State

    IHats hats;

    uint256 facilitatorHatId;
    uint256 registrarHatId;

    uint256 private nonce;

    //Todo - Figure out if mapping is still the best pattern for this
    // arrays might be better

    // maps nonce to request
    mapping(uint256 => Request) public requests;
    // maps grant ship HatID to ship
    mapping(uint256 => Ship) public ships;
    // maps grantee Hat ID to Grantee
    mapping(uint256 => Grantee) public grantees;

    // Events

    // Errors

    error NotAuthorized();
    error RegistrarHatNotConfigured();
    error ShipDoesNotExist();
    error RequestDoesNotExist();
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
        uint256 indexed granteeHatId,
        uint32 metaType,
        string metadata
    );

    event GranteeAdded(
        uint256 indexed granteeHatId,
        uint256 indexed granteeOperatorId,
        address indexed recipientAddress,
        uint32 metaType,
        string metadata
    );

    event ShipDeployed(
        uint256 indexed shipId,
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
        uint256 _registrarHatId,
        bytes[3] memory _shipsData
    ) {
        hats = IHats(_hatsAddress);
        facilitatorHatId = _facilitatorHatId;
        registrarHatId = _registrarHatId;

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

    function registerGrantee(
        address _recipientAddress,
        address[] calldata _operators,
        uint32 _metaType,
        string calldata _metadata
    ) public {
        if (!hats.isWearerOfHat(address(this), registrarHatId)) {
            revert RegistrarHatNotConfigured();
        }

        uint256 granteeHatId = hats.createHat(
            registrarHatId,
            // Todo - Figure out the metadata standard for the hats interface and replicate
            "Grantee Hat",
            1,
            address(0),
            address(0),
            true,
            ""
        );

        hats.mintHat(granteeHatId, _recipientAddress);

        uint256 granteeOperatorId = hats.createHat(
            granteeHatId,
            // Todo - Figure out the metadata standard for the hats interface and replicate
            "Grantee operator role",
            uint32(_operators.length),
            address(0),
            address(0),
            true,
            ""
        );
        // Todo - Figure out gas here
        // In order to use batch minting, we need to create an array of the
        // same size as the number of operators. Is it cheaper to loop twice and batch
        // mint or loop once and mint individually?
        for (uint256 i = 0; i < _operators.length; i++) {
            hats.mintHat(granteeOperatorId, _operators[i]);
        }

        grantees[granteeHatId] = Grantee({
            recipientAddress: _recipientAddress,
            granteeOperatorId: granteeOperatorId,
            verified: false,
            metadata: Metadata({metaType: _metaType, data: _metadata})
        });

        emit GranteeAdded(
            granteeHatId,
            granteeOperatorId,
            _recipientAddress,
            _metaType,
            _metadata
        );
    }

    // function _createGrantee(
    //     address _recipientAddress,
    //     uint256 _granteeOperatorId,
    //     uint32 _metaType,
    //     string memory _metadata,
    //     string memory _imgUrl
    // ) internal {
    //     grantees[granteeHatId] = Grantee({
    //         recipientAddress: _recipientAddress,
    //         granteeOperatorId: _granteeOperatorId,
    //         metadata: Metadata({metaType: _metaType, data: _metadata})
    //     });

    //     emit GranteeAdded(
    //         granteeHatId,
    //         _granteeOperatorId,
    //         _recipientAddress,
    //         _metaType,
    //         _metadata
    //     );
    // }

    function createRequest(
        uint256 _shipHatId,
        uint256 _amountRequested,
        uint32 _metaType,
        string memory _metadata,
        uint256 _granteeHatId,
        // TODO: delete this argument if separate calls works better
        bytes calldata _granteeData
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
            metadata: Metadata({metaType: _metaType, data: _metadata}),
            shipReviewScore: 0,
            granteeHatId: _granteeHatId
        });

        ship.amountPending = _amountRequested + ship.amountPending;
        Grantee memory currentGrantee = grantees[_granteeHatId];

        emit RequestCreated(
            nonce,
            _shipHatId,
            ship.operatorHatId,
            _amountRequested,
            block.timestamp,
            _granteeHatId,
            _metaType,
            _metadata
        );

        unchecked {
            ++nonce;
        }
    }

    function rejectRequest(uint256 _requestId) public onlyFacilitator {
        Request storage request = requests[_requestId];
        if (request.operatorId == 0) revert RequestDoesNotExist();

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
        if (request.operatorId == 0) revert RequestDoesNotExist();
        if (request.status != Status.Pending) revert IncorrectRequestStatus();

        request.status = Status.Approved;

        // write event
        emit RequestStatusChanged(_requestId, Status.Approved);
    }

    function distributeRequest(uint256 _requestId) public onlyFacilitator {
        Request storage request = requests[_requestId];

        if (request.operatorId == 0) revert RequestDoesNotExist();
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
        if (request.operatorId == 0) revert RequestDoesNotExist();

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
