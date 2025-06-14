// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Script.sol";
import {SquadSafeVault} from "../src/SquadSafeVault.sol";

/// @title DeploySquadSafeVault
/// @notice Minimal Foundry deployment script for SquadSafeVault
contract DeploySquadSafeVault is Script {
    function run() public {
        // --- Hardcoded values for local/test deployment ---
        uint256 minVotes = 2;
        address owner = 0xa100000000000000000000000000000000000001;
        // --- End hardcoded values ---

        vm.startBroadcast();
        SquadSafeVault vault = new SquadSafeVault(minVotes, owner);
        vm.stopBroadcast();

        // Log deployed address for easy reference
        console2.log("SquadSafeVault deployed at:", address(vault));
        console2.log("Owner:", owner);
        console2.log("minVotes:", minVotes);
    }
}
