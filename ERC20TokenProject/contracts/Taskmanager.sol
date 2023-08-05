// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/ShortStrings.sol";
import "./deploying_contract.sol";

interface IToken {  // FirstOff we should deploy the Token contract and use this contract via its interface with contract address like IToken(addr).test()
    function mintMinerReward() external;
    function addContributers() external returns(uint);
}

contract TaskManager is Ownable {
    using Math for uint;
    using Address for address;
    using Strings for string;
    using ShortStrings for string;

    constructor(address _token_contract_addr, address _the_task_owner, bytes32 _task_id_by_script) public {
        require(_the_task_owner != address(0));
        task._task_id = 2;
        OWNER_TASK = _the_task_owner;
     }
     
    struct TaskDetail {
        string _task; uint _task_id;
        TaskStatus _task_status; address _task_owner;
        uint _task_date_created;
    }

    enum TaskStatus { COMPLETED, PENDING, CANCELED }

    TaskDetail public task;
    TaskDetail[] public tasks_list_struct;

    address public OWNER_TASK;

    mapping (address => uint) public TaskByOwner;

    event TaskCreated(
        address indexed task_owner_event, uint indexed task_created_event,
        uint indexed task_id_event
    );

    function utfStringLength(string memory str) pure internal returns (uint length) {
        uint i=0;
        bytes memory string_rep = bytes(str);

        while (i<string_rep.length)
        {
            if (string_rep[i]>>7==0) i+=1;
            else if (string_rep[i]>>5==bytes1(uint8(0x6))) i+=2; 

            else if (string_rep[i]>>4==bytes1(uint8(0xE))) i+=3;

            else if (string_rep[i]>>3==bytes1(uint8(0x1E))) i+=4;

            else i+=1;
            length++;
        }
    }

    function getTaskMessageInHashed(string memory _task_to_hash_input) 
        public pure returns(bytes32 hash_out) {
            require(utfStringLength(_task_to_hash_input) > 4, "invalid task data");
            hash_out = keccak256(abi.encodePacked(_task_to_hash_input)); // -> _hashed_message_for_sign
    }

    // sign message
    function _signedTaskHashedMessage(bytes32 _hashed_message_for_sign)
        internal pure returns(bytes32 signing_message) {
            signing_message = keccak256(abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                _hashed_message_for_sign
            ));
    }

    // split the data into ram in assembly
    function _split(bytes32 _signed_message_for_split) 
        internal pure returns(bytes32 s, bytes32 r, uint8 v) {
            require(_signed_message_for_split.length == 65, "nivalid signature");

            assembly {
                s := mload(add(_signed_message_for_split, 32))
                r := mload(add(_signed_message_for_split, 64))
                v := byte(0, add(_signed_message_for_split, 96))
            }
        }

    function recover(bytes32 _task_signed_message_for_recover, bytes32 _sig) 
        internal pure returns(address) {
            (bytes32 s, bytes32 r, uint8 v) = _split(_sig);
            return ecrecover(_task_signed_message_for_recover, v, r, s);
        }

    // verify signed message to the address
    function Verify(string memory _task_message_for_verify, address _task_owner_for_verify, bytes32 _sig)
        external pure returns(bool is_owner) {
            bytes32 hashed_value = getTaskMessageInHashed(_task_message_for_verify);
            bytes32 signed_message_value = _signedTaskHashedMessage(hashed_value);

            address recovered_addr = recover(signed_message_value, _sig);
            return recovered_addr == _task_owner_for_verify;
        }


    function _generateIdForTask(string memory _task, address _task_owner, bytes32 _random_hash_val) private view returns(bytes32 hashed) {
        // ShortString stask = _task.toShortString(); 
        require(!(_task_owner == address(0) && utfStringLength(_task) > 4));

        // nonce for restricting hash collision issue
        uint nonce = uint(keccak256(abi.encodePacked(
            block.timestamp, block.prevrandao
        ))) % 1000;

        hashed = keccak256(abi.encodePacked(_task, _task_owner ,nonce));
    }

    // creating task based on Taskdetail struct
     function createTask(string memory _task_input, address _task_owner_input, bytes32 _task_hashed_val_input) external 
        virtual returns(bool) {
            require(_task_owner_input != address(0), "invalid address");
            
            task._task = _task_input;
            // task._task_id = uint(keccak256("test"));
            bytes32 hash_generated_via_oracle = _generateIdForTask(_task_input, _task_owner_input, _task_hashed_val_input);
            task._task_id = uint(hash_generated_via_oracle);
            task._task_status = TaskStatus.PENDING;
            task._task_owner = _task_owner_input;
            task._task_date_created = block.timestamp;

            TaskByOwner[task._task_owner] = task._task_id;
            tasks_list_struct.push(task);

            emit TaskCreated(task._task_owner, task._task_date_created, task._task_id);
            assert(TaskByOwner[_task_owner_input] == task._task_id);
    }


    function removeTask(uint _task_id_for_remove) public returns(bool) {
        require(!(_task_id_for_remove > tasks_list_struct.length && TaskByOwner[msg.sender] != _task_id_for_remove));
        uint len = tasks_list_struct.length;
        bool deleted = false;

        for(uint i =0; i < len; i++) {
            if (tasks_list_struct[i]._task_id == _task_id_for_remove) {
                tasks_list_struct[len - 1] = tasks_list_struct[i];
                tasks_list_struct.pop();
                
                require(tasks_list_struct.length < len, "Somwthing went occured in task removing");
                deleted = true;
            }
        }

        return deleted; // if task finds among all of tasks, this function will returns true and vise versa.
    }


    // completing task and get KIA token reward via RewardContract;  
    function completeTask(address _token_reward_contract_addr, uint _task_id_for_complete) public payable returns(bool success) {
        require(!(_task_id_for_complete > tasks_list_struct.length && TaskByOwner[msg.sender] != _task_id_for_complete));

        if(this.removeTask(_task_id_for_complete) == true) {
            (bool success, bytes memory data) = _token_reward_contract_addr.call{value:100}
            (
                abi.encodeWithSignature("_beforeTokenTransfer(address,address,uint256   )", 
                    Exercise(_token_reward_contract_addr).who_is_owner() , msg.sender, 100)
            );
        }
    }
}