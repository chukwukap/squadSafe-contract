// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Script.sol";
import {SquadSafeVault} from "../src/SquadSafeVault.sol";

/// @title DeploySquadSafeVault
/// @notice Foundry deployment script for SquadSafeVault
/// @dev Set the OWNER environment variable or edit below for the initial owner.
contract DeploySquadSafeVault is Script {
    function setUp() public pure {}

    function run() public {
        // Use environment variable for owner, fallback to msg.sender
        address owner = vm.envOr("OWNER", msg.sender);

        vm.startBroadcast();
        SquadSafeVault vault = new SquadSafeVault(owner);
        vm.stopBroadcast();

        // Log deployed address for easy reference
        console2.log("SquadSafeVault deployed at:", address(vault));
        console2.log("Owner:", owner);
    }
}
