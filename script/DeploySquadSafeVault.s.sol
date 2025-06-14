// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Script.sol";
import {SquadSafeVault} from "../src/SquadSafeVault.sol";

/// @title DeploySquadSafeVault
/// @notice Foundry deployment script for SquadSafeVault
/// @dev Set the OWNER environment variable or edit below for the initial owner.
contract DeploySquadSafeVault is Script {
    function setUp() public pure {}

    /// @dev Helper to parse comma-separated address string into address array
    function parseMembers(
        string memory membersStr
    ) internal pure returns (address[] memory) {
        bytes memory strBytes = bytes(membersStr);
        uint256 count = 1;
        for (uint256 i = 0; i < strBytes.length; i++) {
            if (strBytes[i] == ",") count++;
        }
        address[] memory members = new address[](count);
        uint256 last = 0;
        uint256 idx = 0;
        for (uint256 i = 0; i <= strBytes.length; i++) {
            if (i == strBytes.length || strBytes[i] == ",") {
                bytes memory addrBytes = new bytes(i - last);
                for (uint256 j = last; j < i; j++) {
                    addrBytes[j - last] = strBytes[j];
                }
                members[idx] = parseAddr(string(addrBytes));
                idx++;
                last = i + 1;
            }
        }
        return members;
    }

    /// @dev Helper to parse address from string (0x...)
    function parseAddr(string memory _a) internal pure returns (address) {
        bytes memory tmp = bytes(_a);
        uint160 iaddr = 0;
        uint160 b1;
        uint160 b2;
        for (uint256 i = 2; i < 2 + 2 * 20; i += 2) {
            iaddr *= 256;
            b1 = uint160(uint8(tmp[i]));
            b2 = uint160(uint8(tmp[i + 1]));
            b1 = b1 >= 97
                ? b1 - 87
                : b1 >= 65
                    ? b1 - 55
                    : b1 - 48;
            b2 = b2 >= 97
                ? b2 - 87
                : b2 >= 65
                    ? b2 - 55
                    : b2 - 48;
            iaddr += (b1 * 16 + b2);
        }
        return address(iaddr);
    }

    function run() public {
        // --- Hardcoded values for local/test deployment ---
        uint256 minVotes = 2;
        address owner = 0xA100000000000000000000000000000000000001;
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
