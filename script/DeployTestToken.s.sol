// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console2} from "forge-std/Script.sol";
import {TestToken} from "../src/TestToken.sol";

/// @dev Deploys TestToken and optionally mints to a specified address (e.g., the vault)
contract DeployTestToken is Script {
    function run() external {
        address deployer = msg.sender;
        vm.startBroadcast();
        TestToken token = new TestToken();
        console2.log("TestToken deployed at:", address(token));

        // Mint initial supply to deployer for testing/demo
        uint256 initialSupply = 1_000_000 ether;
        token.mint(deployer, initialSupply);
        console2.log("Minted", initialSupply, "TTK to deployer", deployer);

        // Optionally, mint to the vault (set VAULT_ADDRESS before running if needed)
        address VAULT_ADDRESS = vm.envOr("VAULT_ADDRESS", address(0));
        if (VAULT_ADDRESS != address(0)) {
            uint256 vaultAmount = 100_000 ether;
            token.mint(VAULT_ADDRESS, vaultAmount);
            console2.log("Minted", vaultAmount, "TTK to vault", VAULT_ADDRESS);
        }
        vm.stopBroadcast();
    }
}
