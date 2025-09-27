// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IL2Registry} from "../interfaces/IL2Registry.sol";
contract L2Registrar {
    error LabelTooShort(uint256 length);
    error LabelUnavailable(string label);
    error InvalidOwner();
    error EmptyLabel();
    event NameRegistered(string indexed label, address indexed owner, uint256 nullifierHash);

    IL2Registry public immutable registry;
    uint256 public immutable chainId;
    uint256 public immutable coinType;
    uint256 internal immutable groupId = 1;
    uint256 public constant MIN_LABEL_LENGTH = 3;

    mapping(uint256 => bool) internal nullifierHashes;
    struct ProfileData {
        string nickname;
        string bio;
        string location;
        string twitter;
    }
    constructor(address _registry) {
        if (_registry == address(0)) revert InvalidOwner();

        uint256 _chainId;
        assembly {
            _chainId := chainid()
        }
        chainId = _chainId;

        // ENSIP-11 coinType calculation for the current chain (Base Sepolia testnet)
        coinType = (0x80000000 | _chainId);

        registry = IL2Registry(_registry);
    }

    function demoRegister(
        string calldata label,
        address owner,
        ProfileData calldata profileData
    ) external returns (bytes32) {
        _validateRegistration(label, owner);
        bytes32 node = _performRegistration(label, owner, profileData);
        emit NameRegistered(label, owner, 0);
        return node;
    }

    function available(string calldata label) external view returns (bool) {
        if (bytes(label).length == 0) return false;
        if (bytes(label).length < MIN_LABEL_LENGTH) return false;
        
        bytes32 node = _labelToNode(label);
        uint256 tokenId = uint256(node);

        try registry.ownerOf(tokenId) {
            return false;
        } catch {
            return true;
        }
    }

    function _validateRegistration(string calldata label, address owner) internal view {
        if (bytes(label).length == 0) revert EmptyLabel();
        if (bytes(label).length < MIN_LABEL_LENGTH) revert LabelTooShort(bytes(label).length);
        if (owner == address(0)) revert InvalidOwner();

        bytes32 node = _labelToNode(label);
        uint256 tokenId = uint256(node);

        try registry.ownerOf(tokenId) {
            revert LabelUnavailable(label);
        } catch {}
    }

    function _performRegistration(
        string calldata label,
        address owner,
        ProfileData calldata profileData
    ) internal returns (bytes32) {
        bytes32 node = registry.createSubnode(
            registry.baseNode(),
            label,
            owner,
            new bytes[](0)
        );

        bytes memory addr = abi.encodePacked(owner);

        // Set the forward address for the current chain (Celo)
        registry.setAddr(node, coinType, addr);

        // Set the forward address for mainnet ETH (coinType 60) for cross-chain compatibility
        registry.setAddr(node, 60, addr);

        _setProfileData(node, profileData);
        return node;
    }

    function _setProfileData(bytes32 node, ProfileData memory profileData) internal {
        if (bytes(profileData.nickname).length > 0) {
            registry.setText(node, "nickname", profileData.nickname);
        }
        if (bytes(profileData.bio).length > 0) {
            registry.setText(node, "description", profileData.bio);
        }
        if (bytes(profileData.location).length > 0) {
            registry.setText(node, "location", profileData.location);
        }
        if (bytes(profileData.twitter).length > 0) {
            registry.setText(node, "twitter", profileData.twitter);
        }
    }

    function _labelToNode(string calldata label) private view returns (bytes32) {
        return registry.makeNode(registry.baseNode(), label);
    }
}
