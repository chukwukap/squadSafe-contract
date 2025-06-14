// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "src/SquadSafeVault.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract ERC20Mock is IERC20 {
    string public name = "MockToken";
    string public symbol = "MTK";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    function mint(address to, uint256 amount) public {
        balanceOf[to] += amount;
        totalSupply += amount;
        emit Transfer(address(0), to, amount);
    }
    function transfer(address to, uint256 amount) public returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Insufficient");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }
    function approve(address spender, uint256 amount) public returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        require(balanceOf[from] >= amount, "Insufficient");
        require(allowance[from][msg.sender] >= amount, "Not allowed");
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        allowance[from][msg.sender] -= amount;
        emit Transfer(from, to, amount);
        return true;
    }
}

contract SquadSafeVaultTest is Test {
    SquadSafeVault vault;
    address alice = address(0xA1);
    address bob = address(0xB2);
    address carol = address(0xC3);
    address recipient = address(0xD4);
    uint256 minVotes = 2;
    ERC20Mock token;

    function setUp() public {
        vm.startPrank(alice);
        vault = new SquadSafeVault(minVotes, alice);
        vault.addMember(alice);
        vault.addMember(bob);
        vault.addMember(carol);
        vm.stopPrank();
        token = new ERC20Mock();
        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);
        vm.deal(carol, 10 ether);
        token.mint(alice, 1000 ether);
        token.mint(bob, 1000 ether);
        token.mint(carol, 1000 ether);
    }

    function testDepositETH() public {
        vm.prank(alice);
        vault.depositETH{value: 1 ether}();
    }

    function testDepositERC20() public {
        vm.startPrank(alice);
        token.approve(address(vault), 100 ether);
        vault.depositERC20(address(token), 100 ether);
        vm.stopPrank();
    }

    function testProposeAndVoteAndExecuteETH() public {
        vm.prank(alice);
        vault.depositETH{value: 2 ether}();
        vm.prank(alice);
        uint256 pid = vault.propose(
            address(0),
            1 ether,
            recipient,
            "Pay for hotel"
        );
        vm.prank(bob);
        vault.vote(pid, true);
        vm.prank(carol);
        vault.vote(pid, true);
        vm.warp(block.timestamp + 2 days);
        uint256 balBefore = recipient.balance;
        vm.prank(alice);
        vault.execute(pid);
        assertEq(recipient.balance, balBefore + 1 ether);
    }

    function testProposeAndVoteAndExecuteERC20() public {
        vm.startPrank(alice);
        token.approve(address(vault), 200 ether);
        vault.depositERC20(address(token), 200 ether);
        vm.stopPrank();
        vm.prank(alice);
        uint256 pid = vault.propose(
            address(token),
            50 ether,
            recipient,
            "Pay for dinner"
        );
        vm.prank(bob);
        vault.vote(pid, true);
        vm.prank(carol);
        vault.vote(pid, true);
        vm.warp(block.timestamp + 2 days);
        uint256 balBefore = token.balanceOf(recipient);
        vm.prank(bob);
        vault.execute(pid);
        assertEq(token.balanceOf(recipient), balBefore + 50 ether);
    }

    function testOnlyMemberCanPropose() public {
        address outsider = address(0xE5);
        vm.expectRevert("Not a group member");
        vm.prank(outsider);
        vault.propose(address(0), 1 ether, recipient, "Outsider");
    }

    function testOnlyMemberCanVote() public {
        vm.prank(alice);
        uint256 pid = vault.propose(address(0), 1 ether, recipient, "Vote");
        address outsider = address(0xE5);
        vm.expectRevert("Not a group member");
        vm.prank(outsider);
        vault.vote(pid, true);
    }

    function testDoubleVotingNotAllowed() public {
        vm.prank(alice);
        uint256 pid = vault.propose(address(0), 1 ether, recipient, "Vote");
        vm.prank(bob);
        vault.vote(pid, true);
        vm.expectRevert("Already voted");
        vm.prank(bob);
        vault.vote(pid, false);
    }

    function testCannotExecuteEarly() public {
        vm.prank(alice);
        uint256 pid = vault.propose(address(0), 1 ether, recipient, "Vote");
        vm.prank(bob);
        vault.vote(pid, true);
        vm.expectRevert("Voting not ended");
        vm.prank(alice);
        vault.execute(pid);
    }

    function testCannotExecuteWithInsufficientVotes() public {
        vm.prank(alice);
        uint256 pid = vault.propose(address(0), 1 ether, recipient, "Vote");
        vm.prank(bob);
        vault.vote(pid, true);
        vm.warp(block.timestamp + 2 days);
        vm.expectRevert("Not enough votes");
        vm.prank(alice);
        vault.execute(pid);
    }

    function testAddMemberOnlyOwner() public {
        address newGuy = address(0xE6);
        vm.prank(alice);
        vault.addMember(newGuy);
        assertTrue(vault.isMember(newGuy));
    }

    function testAddMemberNotOwnerReverts() public {
        address newGuy = address(0xE6);
        vm.prank(bob);
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                bob
            )
        );
        vault.addMember(newGuy);
    }

    function testAddDuplicateMemberReverts() public {
        vm.prank(alice);
        vm.expectRevert("Already a member");
        vault.addMember(alice);
    }

    function testAddZeroAddressReverts() public {
        vm.prank(alice);
        vm.expectRevert("Invalid address");
        vault.addMember(address(0));
    }

    function testRemoveMemberOnlyOwner() public {
        vm.prank(alice);
        vault.removeMember(bob);
        assertFalse(vault.isMember(bob));
    }

    function testRemoveMemberNotOwnerReverts() public {
        vm.prank(bob);
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                bob
            )
        );
        vault.removeMember(carol);
    }

    function testRemoveNonMemberReverts() public {
        address outsider = address(0xE7);
        vm.prank(alice);
        vm.expectRevert("Not a member");
        vault.removeMember(outsider);
    }

    function testRemoveLastMemberReverts() public {
        vm.startPrank(alice);
        vault.removeMember(bob);
        vault.removeMember(carol);
        vm.expectRevert("Cannot remove last member");
        vault.removeMember(alice);
        vm.stopPrank();
    }

    function testSetVotingPeriodOnlyOwner() public {
        vm.prank(alice);
        vault.setVotingPeriod(2 days);
    }

    function testSetVotingPeriodNotOwnerReverts() public {
        vm.prank(bob);
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                bob
            )
        );
        vault.setVotingPeriod(2 days);
    }

    function testSetMinVotesOnlyOwner() public {
        vm.prank(alice);
        vault.setMinVotes(3);
    }

    function testSetMinVotesNotOwnerReverts() public {
        vm.prank(bob);
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                bob
            )
        );
        vault.setMinVotes(3);
    }

    function testGetProposal() public {
        vm.prank(alice);
        uint256 pid = vault.propose(address(0), 1 ether, recipient, "Test");
        (
            address token,
            uint256 amount,
            address to,
            string memory reason,
            uint256 votesFor,
            uint256 votesAgainst,
            uint256 deadline,
            bool executed
        ) = vault.getProposal(pid);
        assertEq(token, address(0));
        assertEq(amount, 1 ether);
        assertEq(to, recipient);
        assertEq(reason, "Test");
        assertEq(votesFor, 0);
        assertEq(votesAgainst, 0);
        assertEq(executed, false);
    }

    function testGetMembers() public {
        address[] memory m = vault.getMembers();
        assertEq(m.length, 3);
        assertEq(m[0], alice);
        assertEq(m[1], bob);
        assertEq(m[2], carol);
    }

    function testOnlyMemberModifierReverts() public {
        address outsider = address(0xE8);
        vm.expectRevert();
        vm.prank(outsider);
        vault.propose(address(0), 1 ether, address(0xD9), "Should revert");
    }
}
