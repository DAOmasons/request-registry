// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "hats-protocol/Interfaces/IHats.sol";

contract MockHats is IHats {
    // Mock state variables
    mapping(address => mapping(uint256 => bool)) private _isWearerOfHat;
    mapping(uint256 => bool) private _hatStatus;
    mapping(uint256 => address) private _hatEligibilityModule;

    // Constructor (if needed)
    constructor() {
        // Initialize mock state variables if needed
    }

    function isWearerOfHat(
        address user,
        uint256 hatId
    ) external view override returns (bool) {
        return _isWearerOfHat[user][hatId];
    }

    function checkHatStatus(
        uint256 hatId
    ) external view override returns (bool) {
        return _hatStatus[hatId];
    }

    function getHatEligibilityModule(
        uint256 hatId
    ) external view override returns (address) {
        return _hatEligibilityModule[hatId];
    }

    // Mock helper functions
    function setWearerOfHat(address user, uint256 hatId, bool isWearer) public {
        _isWearerOfHat[user][hatId] = isWearer;
    }
    
    function setHatStatus(uint256 hatId, bool status) public override returns (bool) {
        _hatStatus[hatId] = status;
        return true; // Or return a value that makes sense for your test scenarios
    }


    function setHatEligibilityModule(uint256 hatId, address module) public {
        _hatEligibilityModule[hatId] = module;
    }

    // Implement remaining interface methods
    // These methods can be left empty or implemented with simple return values
    // depending on how they are used in your RequestRegistry contract

    function mintTopHat(
        address,
        string memory,
        string memory
    ) external pure override returns (uint256) {
        return 0; // Example implementation, should be tailored to your needs
    }

    // Add other IHats methods with dummy implementations
    // ...

    // Implement remaining IHatsIdUtilities, HatsErrors, HatsEvents functions as needed
    // ...
    function buildHatId(
        uint256 _admin,
        uint16 _newHat
    ) external pure override returns (uint256 id) {}

    function getHatLevel(
        uint256 _hatId
    ) external view override returns (uint32 level) {}

    function getLocalHatLevel(
        uint256 _hatId
    ) external pure override returns (uint32 level) {}

    function isTopHat(
        uint256 _hatId
    ) external view override returns (bool _topHat) {}

    function isLocalTopHat(
        uint256 _hatId
    ) external pure override returns (bool _localTopHat) {}

    function isValidHatId(
        uint256 _hatId
    ) external view override returns (bool validHatId) {}

    function getAdminAtLevel(
        uint256 _hatId,
        uint32 _level
    ) external view override returns (uint256 admin) {}

    function getAdminAtLocalLevel(
        uint256 _hatId,
        uint32 _level
    ) external pure override returns (uint256 admin) {}

    function getTopHatDomain(
        uint256 _hatId
    ) external view override returns (uint32 domain) {}

    function getTippyTopHatDomain(
        uint32 _topHatDomain
    ) external view override returns (uint32 domain) {}

    function noCircularLinkage(
        uint32 _topHatDomain,
        uint256 _linkedAdmin
    ) external view override returns (bool notCircular) {}

    function sameTippyTopHatDomain(
        uint32 _topHatDomain,
        uint256 _newAdminHat
    ) external view override returns (bool sameDomain) {}

    function createHat(
        uint256 _admin,
        string calldata _details,
        uint32 _maxSupply,
        address _eligibility,
        address _toggle,
        bool _mutable,
        string calldata _imageURI
    ) external override returns (uint256 newHatId) {}

    function batchCreateHats(
        uint256[] calldata _admins,
        string[] calldata _details,
        uint32[] calldata _maxSupplies,
        address[] memory _eligibilityModules,
        address[] memory _toggleModules,
        bool[] calldata _mutables,
        string[] calldata _imageURIs
    ) external override returns (bool success) {}

    function getNextId(
        uint256 _admin
    ) external view override returns (uint256 nextId) {}

    function mintHat(
        uint256 _hatId,
        address _wearer
    ) external override returns (bool success) {}

    function batchMintHats(
        uint256[] calldata _hatIds,
        address[] calldata _wearers
    ) external override returns (bool success) {}

    function setHatWearerStatus(
        uint256 _hatId,
        address _wearer,
        bool _eligible,
        bool _standing
    ) external override returns (bool updated) {}

    function checkHatWearerStatus(
        uint256 _hatId,
        address _wearer
    ) external override returns (bool updated) {}

    function renounceHat(uint256 _hatId) external override {}

    function transferHat(
        uint256 _hatId,
        address _from,
        address _to
    ) external override {}

    function makeHatImmutable(uint256 _hatId) external override {}

    function changeHatDetails(
        uint256 _hatId,
        string memory _newDetails
    ) external override {}

    function changeHatEligibility(
        uint256 _hatId,
        address _newEligibility
    ) external override {}

    function changeHatToggle(
        uint256 _hatId,
        address _newToggle
    ) external override {}

    function changeHatImageURI(
        uint256 _hatId,
        string memory _newImageURI
    ) external override {}

    function changeHatMaxSupply(
        uint256 _hatId,
        uint32 _newMaxSupply
    ) external override {}

    function requestLinkTopHatToTree(
        uint32 _topHatId,
        uint256 _newAdminHat
    ) external override {}

    function approveLinkTopHatToTree(
        uint32 _topHatId,
        uint256 _newAdminHat,
        address _eligibility,
        address _toggle,
        string calldata _details,
        string calldata _imageURI
    ) external override {}

    function unlinkTopHatFromTree(
        uint32 _topHatId,
        address _wearer
    ) external override {}

    function relinkTopHatWithinTree(
        uint32 _topHatDomain,
        uint256 _newAdminHat,
        address _eligibility,
        address _toggle,
        string calldata _details,
        string calldata _imageURI
    ) external override {}

    function viewHat(
        uint256 _hatId
    )
        external
        view
        override
        returns (
            string memory details,
            uint32 maxSupply,
            uint32 supply,
            address eligibility,
            address toggle,
            string memory imageURI,
            uint16 lastHatId,
            bool mutable_,
            bool active
        )
    {}

    function isAdminOfHat(
        address _user,
        uint256 _hatId
    ) external view override returns (bool isAdmin) {}

    function isInGoodStanding(
        address _wearer,
        uint256 _hatId
    ) external view override returns (bool standing) {}

    function isEligible(
        address _wearer,
        uint256 _hatId
    ) external view override returns (bool eligible) {}

    function getHatToggleModule(
        uint256 _hatId
    ) external view override returns (address toggle) {}

    function getHatMaxSupply(
        uint256 _hatId
    ) external view override returns (uint32 maxSupply) {}

    function hatSupply(
        uint256 _hatId
    ) external view override returns (uint32 supply) {}

    function getImageURIForHat(
        uint256 _hatId
    ) external view override returns (string memory _uri) {}

    function balanceOf(
        address wearer,
        uint256 hatId
    ) external view override returns (uint256 balance) {}

    function balanceOfBatch(
        address[] calldata _wearers,
        uint256[] calldata _hatIds
    ) external view override returns (uint256[] memory) {}

    function uri(
        uint256 id
    ) external view override returns (string memory _uri) {}
}
