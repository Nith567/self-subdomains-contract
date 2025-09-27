// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { CryptoNomads } from "../src/cryptoNomads.sol";
import { BaseScript } from "./Base.s.sol";
import { CountryCodes } from "@selfxyz/contracts/contracts/libraries/CountryCode.sol";
import { console } from "forge-std/console.sol";
import { SelfUtils } from "@selfxyz/contracts/contracts/libraries/SelfUtils.sol";

/// @title DeployCryptoNomads
/// @notice Deployment script for CryptoNomads contract using standard deployment
contract DeployCryptoNomads is BaseScript {
    // Custom errors for deployment verification
    error DeploymentFailed();

    /// @notice Main deployment function using standard deployment
    /// @return cryptoNomads The deployed CryptoNomads contract instance
    /// @dev Requires the following environment variables:
    ///      - IDENTITY_VERIFICATION_HUB_ADDRESS: Address of the Self Protocol verification hub
    ///      - PLACEHOLDER_SCOPE: Placeholder scope value (defaults to 1)

    function run() public broadcast returns (CryptoNomads cryptoNomads) {
        address hubAddress = vm.envAddress("IDENTITY_VERIFICATION_HUB_ADDRESS");
        uint256 placeholderScope = vm.envOr("PLACEHOLDER_SCOPE", uint256(1)); // Use placeholder scope
        
        string[] memory forbiddenCountries = new string[](1);
        forbiddenCountries[0] = CountryCodes.PAKISTAN;
        SelfUtils.UnformattedVerificationConfigV2 memory verificationConfig = SelfUtils.UnformattedVerificationConfigV2({
            olderThan: 18,
            forbiddenCountries: forbiddenCountries,
            ofacEnabled: false
        });

        // Deploy with placeholder scope
        cryptoNomads = new CryptoNomads(hubAddress, placeholderScope, verificationConfig);
        
        // Log deployment information
        console.log("CryptoNomads deployed to:", address(cryptoNomads));
        console.log("Identity Verification Hub:", hubAddress);
        console.log("Placeholder Scope:", placeholderScope);

        // Verify deployment was successful
        if (address(cryptoNomads) == address(0)) revert DeploymentFailed();

        console.log("Deployment and scope setting completed successfully!");
    }
    

}
