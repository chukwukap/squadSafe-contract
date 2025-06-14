// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

/// @title TestToken (TTK) - Simple ERC20 for testing SquadSafe vault
/// @notice Mintable by deployer only. Intended for test/demo use only.
/// @dev Security: Not for production. Minting is restricted to deployer.
contract TestToken is ERC20 {
    address public immutable deployer;

    /// @notice Sets the token name and symbol, and records deployer
    constructor() ERC20("TestToken", "TTK") {
        deployer = msg.sender;
    }

    /// @notice Mint tokens to an address (deployer only)
    /// @param to Recipient address
    /// @param amount Amount to mint (in wei)
    function mint(address to, uint256 amount) external {
        require(msg.sender == deployer, "Only deployer can mint");
        _mint(to, amount);
    }
}
