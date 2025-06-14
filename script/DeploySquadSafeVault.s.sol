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
        // Use environment variables for members, minVotes, and owner
        address[] memory members = vm.envAddressArray("MEMBERS");
        uint256 minVotes = vm.envOr("MIN_VOTES", uint256(1));
        address owner = vm.envOr("OWNER", msg.sender);

        require(members.length > 0, "No members provided");
        require(minVotes > 0, "minVotes must be > 0");

        vm.startBroadcast();
        SquadSafeVault vault = new SquadSafeVault(members, minVotes, owner);
        vm.stopBroadcast();

        // Log deployed address for easy reference
        console2.log("SquadSafeVault deployed at:", address(vault));
        console2.log("Owner:", owner);
        console2.log("Members:");
        for (uint256 i = 0; i < members.length; i++) {
            console2.log(members[i]);
        }
        console2.log("minVotes:", minVotes);
    }
}
