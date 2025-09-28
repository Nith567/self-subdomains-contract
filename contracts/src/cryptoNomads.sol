// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {SelfVerificationRoot} from "@selfxyz/contracts/contracts/abstract/SelfVerificationRoot.sol";
import {ISelfVerificationRoot} from "@selfxyz/contracts/contracts/interfaces/ISelfVerificationRoot.sol";
import {SelfStructs} from "@selfxyz/contracts/contracts/libraries/SelfStructs.sol";
import {SelfUtils} from "@selfxyz/contracts/contracts/libraries/SelfUtils.sol";
import {IIdentityVerificationHubV2} from "@selfxyz/contracts/contracts/interfaces/IIdentityVerificationHubV2.sol";
import {IL2Registry} from "../src/durin-ens/interfaces/IL2Registry.sol";
/**
 * @title CryptoNomads
 * @notice Stores Self Protocol verification data mapped by Discord Username
 * @dev Maps Discord Usernames to verification data for easy retrieval
 */
contract CryptoNomads is SelfVerificationRoot {
    // Basic storage (for compatibility)
    bool public verificationSuccessful;
    ISelfVerificationRoot.GenericDiscloseOutputV2 public lastOutput;
    bytes public lastUserData;
    SelfStructs.VerificationConfigV2 public verificationConfig;
    bytes32 public verificationConfigId;
    address public lastUserAddress;

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


    // Discord Username mapping storage
    struct VerificationData {
        string gender;           // "M", "T", or "F"
        string nationality;      // Country code like "IND", "USA", etc.
        bool isAdult;           // true if olderThan >= 18
        uint256 ageThreshold;   // The actual age threshold (18, 21, etc.)
        address walletAddress;  // Privy wallet address
        bool isVerified;
    }

    // Profile data for ENS registration
    struct ProfileData {
        string nickname;    // Discord username
        string bio;         // Gender info (Male/Female/Trans)
        string location;    // Country from Self Protocol
    }

    // Main mapping: Discord Username -> Verification Data
    mapping(string => VerificationData) public discordVerifications;
    
    // Reverse mapping: Wallet Address -> Discord Username
    mapping(address => string) public walletToDiscordUsername;
    
    // Array to track all verified Discord Usernames (for admin purposes)
    string[] public verifiedDiscordUsernames;
    
    // Events
    event VerificationCompleted(
        ISelfVerificationRoot.GenericDiscloseOutputV2 output,
        bytes userData,
        address userAddress,
        string indexed discordUsername
    );

    event DiscordVerificationStored(
        string indexed discordUsername,
        address indexed walletAddress,
        string gender,
        string nationality,
        bool isAdult
    );

    /**
     * @notice Constructor
     * @param identityVerificationHubV2Address Hub V2 address
     * @param scope Unique scope for your app
     * @param _verificationConfig Verification requirements
     */
    constructor(
        address identityVerificationHubV2Address,
        uint256 scope, 
        SelfUtils.UnformattedVerificationConfigV2 memory _verificationConfig,
        address _registry
    )
        SelfVerificationRoot(identityVerificationHubV2Address, scope)
    {
        verificationConfig = SelfUtils.formatVerificationConfigV2(_verificationConfig);
        verificationConfigId =
     IIdentityVerificationHubV2(identityVerificationHubV2Address).setVerificationConfigV2(verificationConfig);
        
        
        uint256 _chainId;
        assembly {
            _chainId := chainid()
        }
        chainId = _chainId;

        // ENSIP-11 coinType calculation for the current chain (Base Sepolia testnet)
        coinType = (0x80000000 | _chainId);

        registry = IL2Registry(_registry);
    }

    /**
     * @notice Called when Self Protocol verification succeeds
     * @param output Verification results from Self Protocol
     * @param userData Discord Username (passed as userDefinedData)
     */
    function customVerificationHook(
        ISelfVerificationRoot.GenericDiscloseOutputV2 memory output,
        bytes memory userData
    ) internal override {
        // Update basic storage
        verificationSuccessful = true;
        lastOutput = output;
        lastUserData = userData;
        lastUserAddress = address(uint160(output.userIdentifier)); 

        // Extract Discord username from userData (bytes to string conversion)
        // userData contains the Discord username string like "alice" or "cryptonerd42"
        string memory discordUsername = string(userData);
        
        // Check if user is adult (olderThan >= 18)
        bool isAdult = output.olderThan >= 18;
        
        // Store verification data by Discord username
        discordVerifications[discordUsername] = VerificationData({
            gender: output.gender,             // Already comes as "M", "F", or "T"
            nationality: output.nationality,    // Country code like "IND", "USA"
            isAdult: isAdult,                  // true if age >= 18
            ageThreshold: output.olderThan,    // Actual age threshold (18, 21, etc.)
            walletAddress: lastUserAddress,    // Privy wallet address
            isVerified: true
        });
        walletToDiscordUsername[lastUserAddress] = discordUsername;
        
        if (!isDiscordUsernameInArray(discordUsername)) {
            verifiedDiscordUsernames.push(discordUsername);
        }

        // Automatically register ENS name with Self Protocol data
        string memory ensLabel = discordUsername; // Use Discord username directly as ENS label
        
        // Convert gender code to readable string
        string memory genderText;
        if (keccak256(bytes(output.gender)) == keccak256(bytes("M"))) {
            genderText = "Male";
        } else if (keccak256(bytes(output.gender)) == keccak256(bytes("F"))) {
            genderText = "Female";
        } else if (keccak256(bytes(output.gender)) == keccak256(bytes("T"))) {
            genderText = "Trans";
        } else {
            genderText = "Not specified";
        }
        
        // Create profile data
        ProfileData memory profileData = ProfileData({
            nickname: discordUsername,     // Discord username
            bio: genderText,              // Gender from Self Protocol
            location: output.nationality   // Country from Self Protocol
        });
        
        // Try to register ENS name (if available)
        try this.available(ensLabel) returns (bool isAvailable) {
            if (isAvailable) {
                _validateRegistration(ensLabel, lastUserAddress);
                bytes32 node = _performRegistration(ensLabel, lastUserAddress, profileData);
                emit NameRegistered(ensLabel, lastUserAddress, 0);
            }
        } catch {
            // ENS registration failed, continue without it
        }

        // Emit events
        emit VerificationCompleted(output, userData, lastUserAddress, discordUsername);
        emit DiscordVerificationStored(
            discordUsername,
            lastUserAddress,
            output.gender,
            output.nationality,
            isAdult
        );
    }


      // -------------Internal & helpers-------------



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

    function _validateRegistration(string memory label, address owner) internal view {
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
        string memory label,
        address owner,
        ProfileData memory profileData
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
    }

    function _labelToNode(string memory label) private view returns (bytes32) {
        return registry.makeNode(registry.baseNode(), label);
    }

    // ========== VIEW FUNCTIONS ==========

    /**
     * @notice Get all verification data for a Discord Username
     * @param discordUsername The Discord username
     * @return gender The user's gender
     * @return nationality The user's nationality  
     * @return isAdult Whether the user is an adult
     * @return ageThreshold The age threshold used for verification
     * @return walletAddress The user's wallet address
     * @return isVerified Whether the user is verified
     */
    function getVerificationDataByDiscordUsername(string memory discordUsername) 
        external 
        view 
        returns (
            string memory gender,
            string memory nationality,
            bool isAdult,
            uint256 ageThreshold,
            address walletAddress,
            bool isVerified
        ) 
    {
        VerificationData memory data = discordVerifications[discordUsername];
        return (
            data.gender,
            data.nationality,
            data.isAdult,
            data.ageThreshold,
            data.walletAddress,
            data.isVerified
        );
    }

    /**
     * @notice Check if Discord Username is verified
     * @param discordUsername The Discord username
     * @return isVerified Whether the user is verified
     */
    function isDiscordUsernameVerified(string memory discordUsername) 
        external 
        view 
        returns (bool isVerified) 
    {
        return discordVerifications[discordUsername].isVerified;
    }

    /**
     * @notice Get Discord Username from wallet address
     * @param walletAddress The wallet address
     * @return discordUsername The Discord username
     */
    function getDiscordUsernameByWallet(address walletAddress) 
        external 
        view 
        returns (string memory discordUsername) 
    {
        return walletToDiscordUsername[walletAddress];
    }

    /**
     * @notice Get verification data for multiple Discord Usernames
     * @param discordUsernames Array of Discord usernames
     * @return results Array of verification data
     */
    function getBatchVerificationData(string[] memory discordUsernames)
        external
        view
        returns (VerificationData[] memory results)
    {
        results = new VerificationData[](discordUsernames.length);
        for (uint256 i = 0; i < discordUsernames.length; i++) {
            results[i] = discordVerifications[discordUsernames[i]];
        }
        return results;
    }

    /**
     * @notice Get total number of verified users
     * @return count Total verified Discord usernames
     */
    function getTotalVerifiedCount() external view returns (uint256 count) {
        return verifiedDiscordUsernames.length;
    }

    /**
     * @notice Get verified Discord Username by index
     * @param index Index in the verified array
     * @return discordUsername The Discord username at that index
     */
    function getVerifiedDiscordUsernameByIndex(uint256 index) 
        external 
        view 
        returns (string memory discordUsername) 
    {
        require(index < verifiedDiscordUsernames.length, "Index out of bounds");
        return verifiedDiscordUsernames[index];
    }

    // ========== INTERNAL FUNCTIONS ==========

    /**
     * @notice Check if Discord Username is already in verified array
     * @param discordUsername The Discord username to check
     * @return exists Whether it exists in the array
     */
    function isDiscordUsernameInArray(string memory discordUsername) 
        internal 
        view 
        returns (bool exists) 
    {
        for (uint256 i = 0; i < verifiedDiscordUsernames.length; i++) {
            if (keccak256(bytes(verifiedDiscordUsernames[i])) == keccak256(bytes(discordUsername))) {
                return true;
            }
        }
        return false;
    }



    // ========== REQUIRED OVERRIDES ==========

    /**
     * @notice Get config ID for verification
     */
    function getConfigId(
        bytes32 /* destinationChainId */,
        bytes32 /* userIdentifier */,
        bytes memory /* userDefinedData */
    ) public view override returns (bytes32) {
        return verificationConfigId;
    }



    /**
     * @notice Update config ID (admin only - add access control if needed)
     * @param configId New config ID
     */
    function setConfigId(bytes32 configId) external {
        verificationConfigId = configId;
    }

    /**
     * @notice Expose the internal _setScope function for scope updates
     * @param newScope The new scope value to set
     */
    function setScope(uint256 newScope) external {
        _setScope(newScope);
    }

    /**
     * @notice Demo register ENS name with profile data
     * @param label The ENS label to register
     * @param owner The owner address
     * @param profileData Profile data including nickname, bio, location
     */
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
}
