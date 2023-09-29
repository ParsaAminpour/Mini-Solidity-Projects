// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract SimpleVoteV1 is Ownable{
    using ECDSA for uint;
    using Address for address;
   
    uint private constant PERIOD = 3600; // 1 day
    bool private initialized;
    uint public status_number; // Just for proxy checking

    enum VOTE {
        YES, NO, NEUTRAL
    }

    /* NOTE: bytes32 refers to VoteId **/
    mapping(bytes32 => string) public VotesMap; 
    mapping(address => mapping(bytes32 => VOTE)) public VotedMap; 
    mapping(address => uint) public VoterBalances;

    event LogSignature(address indexed owner, bytes32 indexed signature);

    function initialize() external payable {
        require(!initialized, "Contract has been generated an instance before");
        status_number = 77;
        VoterBalances[msg.sender] = msg.value;
        transferOwnership(msg.sender);
        initialized = true;
    }   

    function getStatusNumber() external view returns(uint) {
        return status_number;
    }

    modifier onlyMembers() {
        require(VoterBalances[msg.sender] > 0, "The caller is not a memeber of DAO");
        _;
    }

    function setVote(string memory _vote_message) external onlyOwner onlyMembers returns(bool) {
        bytes32 hash = keccak256(abi.encodePacked(_vote_message));
        bytes32 signature = ECDSA.toEthSignedMessageHash(hash);
        emit LogSignature(msg.sender, signature);

        VotesMap[signature] = _vote_message;
        return true;
    }

    function voting(VOTE _vote, bytes32 _task_signature) external onlyMembers {
        VotedMap[msg.sender][_task_signature] = _vote;
        // This contract wont take shareholders of this DAO because of maintain simple code-base.
    }

    // function addMemeberDao() external onlyOwner() returns(bool) {} // This will add in SimpleVoteV2
}