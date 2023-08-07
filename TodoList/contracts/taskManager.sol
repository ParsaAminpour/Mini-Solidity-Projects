// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/ShortStrings.sol";    
import "./TaskToken.sol";


contract SimpleTaskManager is ERC20 {
    // STATE VARIABLES:
    address public immutable OWNER;
    uint public TOTAL_SUPPLY;
    
    enum TASK_STATAUS { COMPLETED, PENDING, CANCELED }

    // a struct for task
    struct TaskDetails {
        address task_owner; uint task_id; // id will fenerate from VRF
        string task_message; uint task_created_date;
        uint task_cmplete_period; TASK_STATAUS task_status;
    }

    struct User {
        address user_address; uint task_available;
        uint token_rewarded;
    }

    User[] private users_list;
    // a mapping for task owner
    mapping(address => TaskDetails[]) public tasks_map;
    mapping(address => uint[]) public tasks_id_map;

    /** NOTE: The chainlink configuration data is based on sepolia network 
              Change it to your desire network */
    bytes32 internal keyHash;
    uint8 internal fee;

    // a mapping for grant or revoke task from task's owner
    // a list in this pattern(mapping(owner -> task struct))


    constructor() ERC20('TaskToken', 'TASK') public {
        OWNER = msg.sender;
        TOTAL_SUPPLY = 1e21;
        _mint(msg.sender, TOTAL_SUPPLY);
    }


    error UserAvailableError(address user_address);
    function createUser() public returns(bool listed) {
        for(uint i; i < users_list.length; i++) {
            if(!(users_list[i].user_address == msg.sender)) {
                users_list.push(User(msg.sender, 0, 0));
                listed = true;
            }
        }
        listed = false;
        revert("User had already joined to this contract");
    }

    
    function utfStringLength(string memory str) pure internal returns (uint length) {
        uint i=0;
        bytes memory string_rep = bytes(str);

        while (i<string_rep.length) {
            if (string_rep[i]>>7==0) i+=1;
            else if (string_rep[i]>>5==bytes1(uint8(0x6))) i+=2; 

            else if (string_rep[i]>>4==bytes1(uint8(0xE))) i+=3;

            else if (string_rep[i]>>3==bytes1(uint8(0x1E))) i+=4;

            else i+=1;
            length++;
        }
    }

    // signature and verification functions
    function _hashedMessage(string memory _message) internal pure returns(bytes32 hash_result) {
        require(utfStringLength(_message) > 4, "invalid message as a task");
        hash_result = keccak256(abi.encodePacked(_message));
    }

    function _signMessage(bytes32  _hashed_message) internal pure returns(bytes32 signed) {
        require(_hashed_message.length > 4, "invalid hashed message");

        signed = keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32", _hashed_message
        ));
    }

    function _recover(bytes32 _signed_message_hashed, bytes32 _sig_for_validate)
        internal pure returns(address resolve_addr) {
            require(_signed_message_hashed.length + _sig_for_validate.length > 4, "invalid inputs");
            bytes32 s;
            bytes32 r;
            uint8 v;

            assembly {
                s := mload(add(_sig_for_validate, 32))
                r := mload(add(_sig_for_validate, 64))
                v := byte(0, mload(add(_sig_for_validate, 96)))
            }
            resolve_addr =ecrecover(_signed_message_hashed, v, r, s); 
    }

    function Verify(address _signer_for_verify, string memory _message_for_verify, bytes32 _sig_for_verify)
        external pure returns(bool) {
            bytes32 hashed = _hashedMessage(_message_for_verify);
            bytes32 sig = _signMessage(hashed);

            return _recover(sig, _sig_for_verify) == _signer_for_verify;
    }

    // function Related to Task managing:
    
}