// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

/// @title SquadSafeVault
/// @notice Multi-sig group vault for ETH/ERC20 with proposal, voting, and execution logic
/// @dev Designed for integration with XMTP agents and Base L2
contract SquadSafeVault is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Address for address payable;

    // --- Events ---
    event Deposit(address indexed from, address indexed token, uint256 amount);
    event ProposalCreated(
        uint256 indexed proposalId,
        address indexed proposer,
        address token,
        uint256 amount,
        address to,
        string reason
    );
    event Voted(
        uint256 indexed proposalId,
        address indexed voter,
        bool support
    );
    event ProposalExecuted(
        uint256 indexed proposalId,
        address indexed executor
    );
    event MemberAdded(address indexed newMember);
    event MemberRemoved(address indexed removedMember);

    // --- Structs ---
    struct Proposal {
        address token;
        uint256 amount;
        address to;
        string reason;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 deadline;
        bool executed;
        mapping(address => bool) voted;
    }

    // --- State ---
    address[] public members;
    mapping(address => bool) public isMember;
    uint256 public proposalCount;
    mapping(uint256 => Proposal) private proposals;
    uint256 public votingPeriod = 1 days;
    uint256 public minVotes; // e.g., simple majority

    // --- Modifiers ---
    modifier onlyMember() {
        require(isMember[msg.sender], "Not a group member");
        _;
    }

    // --- Constructor ---
    /// @param _minVotes The minimum votes required for execution
    /// @param initialOwner The initial contract owner (for OpenZeppelin 5.x)
    constructor(uint256 _minVotes, address initialOwner) Ownable(initialOwner) {
        minVotes = _minVotes;
    }

    // --- Deposit Functions ---
    function depositETH() external payable {
        emit Deposit(msg.sender, address(0), msg.value);
    }

    function depositERC20(address token, uint256 amount) external {
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        emit Deposit(msg.sender, token, amount);
    }

    // --- Proposal & Voting ---
    function propose(
        address token,
        uint256 amount,
        address to,
        string calldata reason
    ) external onlyMember returns (uint256) {
        proposalCount++;
        Proposal storage p = proposals[proposalCount];
        p.token = token;
        p.amount = amount;
        p.to = to;
        p.reason = reason;
        p.deadline = block.timestamp + votingPeriod;
        emit ProposalCreated(
            proposalCount,
            msg.sender,
            token,
            amount,
            to,
            reason
        );
        return proposalCount;
    }

    function vote(uint256 proposalId, bool support) external onlyMember {
        Proposal storage p = proposals[proposalId];
        require(block.timestamp <= p.deadline, "Voting ended");
        require(!p.voted[msg.sender], "Already voted");
        p.voted[msg.sender] = true;
        if (support) {
            p.votesFor++;
        } else {
            p.votesAgainst++;
        }
        emit Voted(proposalId, msg.sender, support);
    }

    function execute(uint256 proposalId) external nonReentrant onlyMember {
        Proposal storage p = proposals[proposalId];
        require(!p.executed, "Already executed");
        require(block.timestamp > p.deadline, "Voting not ended");
        require(p.votesFor >= minVotes, "Not enough votes");
        p.executed = true;
        if (p.token == address(0)) {
            // ETH transfer
            payable(p.to).sendValue(p.amount);
        } else {
            // ERC20 transfer
            IERC20(p.token).safeTransfer(p.to, p.amount);
        }
        emit ProposalExecuted(proposalId, msg.sender);
    }

    // --- View Functions ---
    function getProposal(
        uint256 proposalId
    )
        external
        view
        returns (
            address token,
            uint256 amount,
            address to,
            string memory reason,
            uint256 votesFor,
            uint256 votesAgainst,
            uint256 deadline,
            bool executed
        )
    {
        Proposal storage p = proposals[proposalId];
        return (
            p.token,
            p.amount,
            p.to,
            p.reason,
            p.votesFor,
            p.votesAgainst,
            p.deadline,
            p.executed
        );
    }

    function getMembers() external view returns (address[] memory) {
        return members;
    }

    // --- Admin Functions ---
    function setVotingPeriod(uint256 _period) external onlyOwner {
        votingPeriod = _period;
    }

    function setMinVotes(uint256 _minVotes) external onlyOwner {
        minVotes = _minVotes;
    }

    /// @notice Add a new member to the group (onlyOwner)
    /// @param newMember The address to add
    function addMember(address newMember) external onlyOwner {
        require(newMember != address(0), "Invalid address");
        require(!isMember[newMember], "Already a member");
        isMember[newMember] = true;
        members.push(newMember);
        emit MemberAdded(newMember);
    }

    /// @notice Remove a member from the group (onlyOwner)
    /// @param member The address to remove
    function removeMember(address member) external onlyOwner {
        require(isMember[member], "Not a member");
        require(members.length > 1, "Cannot remove last member");
        isMember[member] = false;
        // Remove from array
        for (uint256 i = 0; i < members.length; i++) {
            if (members[i] == member) {
                members[i] = members[members.length - 1];
                members.pop();
                break;
            }
        }
        emit MemberRemoved(member);
    }

    // --- TODOs for Advanced Features ---
    // - AI/automation hooks
    // - DeFi integrations
    // - OFAC/compliance screening
    // - Upgradeability (UUPS/proxy)
    // - Gas optimizations
}
