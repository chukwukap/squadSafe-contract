// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {TestToken} from "../src/TestToken.sol";

contract TestTokenTest is Test {
    TestToken token;
    address deployer = address(this);
    address user = address(0xBEEF);

    function setUp() public {
        token = new TestToken();
    }

    function testDeployerIsSet() public {
        assertEq(token.deployer(), deployer);
    }

    function testMintByDeployer() public {
        token.mint(user, 123 ether);
        assertEq(token.balanceOf(user), 123 ether);
    }

    function testMintByNonDeployerReverts() public {
        vm.prank(user);
        vm.expectRevert("Only deployer can mint");
        token.mint(user, 1 ether);
    }

    function testERC20Properties() public {
        assertEq(token.name(), "TestToken");
        assertEq(token.symbol(), "TTK");
        assertEq(token.decimals(), 18);
    }
}
