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
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";  
import "./TaskToken.sol";



contract SimpleTaskManager is ERC20, VRFConsumerBase {
    // STATE VARIABLES:
    address public immutable OWNER; 
    uint public TOTAL_SUPPLY;
    uint private randomResult;
    address public constant TOKEN_CONTRACT = 0x0E39cC01d2a35FFF7629D8607AFE228d7Fb3ca9e;

    event TaskCreated(address indexed cerator, uint indexed task_id_created);
    event TaskRemoved(address indexed remover, uint indexed task_id_removed);
    event EtherReceived(address indexed sender, uint indexed amount);

    enum TASK_STATUS { COMPLETED, PENDING, CANCELED }

    // a struct for task
    struct TaskDetails {
        address task_owner; uint task_id; // id will fenerate from VRF
        string task_message; uint task_created_date;
        uint task_complete_period; TASK_STATUS task_status;
        bytes32 task_signature;
    }

    struct User {
        address user_address; uint task_available;
        uint token_rewarded;
    }

    User[] private users_list;
    // a mapping for task owner
    mapping(address => TaskDetails[]) public tasks_map;
    mapping(uint => address) private task_id_to_owner_map;
    mapping(address => bytes32[]) private tasks_sig_map;
    mapping(uint => TaskDetails) private task_id_map;

    /** NOTE: The chainlink configuration data is based on sepolia network 
              Change it to your desire network */
    bytes32 internal keyHash;
    uint internal fee;

    // a mapping for grant or revoke task from task's owner
    // a list in this pattern(mapping(owner -> task struct))


    constructor() ERC20('TaskToken', 'TASK')
    VRFConsumerBase(
        0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625,
        0x779877A7B0D9E8603169DdbD7836e478b4624789
    ) {
        OWNER = msg.sender;
        TOTAL_SUPPLY = 1e21;
        _mint(msg.sender, TOTAL_SUPPLY);

        keyHash = 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c;
        fee = 0.25 * (10**18);
    }


    error UserAvailableError(address user_address);

    function deposit() external payable {
        emit EtherReceived(msg.sender, msg.value);
    }

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
        internal pure returns(bool) {
            bytes32 hashed = _hashedMessage(_message_for_verify);
            bytes32 sig = _signMessage(hashed);

            return _recover(sig, _sig_for_verify) == _signer_for_verify;
    }


    // Chainlink VRF for getting random number
    function getRandomNumberFromChainlinkVRF() public returns(bytes32 requestId) {
        require(LINK.balanceOf(address(this)) > fee, "Unsufficient LINK balance from contract");
        return requestRandomness(keyHash, fee);
    }

    function fulfillRandomness(bytes32 _requestId, uint randomness) internal override {
        randomResult = randomness;
    }

    function _get_random_number() internal view returns(uint) {
        return randomResult;
    }



    // function Related to Task managing:
    function _generate_task_id(address _owner, string memory _task_message, uint _nonce) 
        internal view returns(uint randint) {
        require(utfStringLength(_task_message) > 4 && _nonce != 0, "invalid inputs");

        randint = uint(keccak256(abi.encodePacked(
            _owner, _task_message, _nonce, block.timestamp
        )));
    }


    function createTask(string memory _task_message, uint _task_complete_date) public returns(bool created) {
        require(!(utfStringLength(_task_message) < 4 && _task_complete_date < block.timestamp),
                "Date inputs are not Valid");
        
        bool user_exist = false;
        for(uint i; i < users_list.length; i++) {
            if(users_list[i].user_address == msg.sender) {
                user_exist = true;
                break;
            }
            
            if(i == users_list.length-1 && users_list[i].user_address != msg.sender) created=false;
        }
        require(user_exist, "First add user to user list"); 


        bytes32 req_id = getRandomNumberFromChainlinkVRF();
        require(req_id.length != 0, "Some error occured for chainlink VRF");
        uint rand_num = _get_random_number();
        uint task_id_generated = _generate_task_id(msg.sender, _task_message, rand_num);
        
        // creating the new task

        // signing ownership of this task by owner
        bytes32 hashed_message_for_sig = _hashedMessage(_task_message);
        bytes32 signed_message_val = _signMessage(hashed_message_for_sig);
        tasks_sig_map[msg.sender].push(signed_message_val);

        TaskDetails memory new_task = TaskDetails(
            msg.sender, rand_num, _task_message, block.timestamp, _task_complete_date, TASK_STATUS.PENDING, signed_message_val);  
        
        tasks_map[msg.sender].push(new_task);
        task_id_to_owner_map[task_id_generated] = msg.sender;
        task_id_map[task_id_generated] = new_task;


        // if(tasks_sig_map[signed_message_val] == msg.sender && task_id_to_owner_map[task_id_generated] == msg.sender) created = true;
        created = true;
    }


    modifier is_task_owner(uint _task_id_for_verify_owner) {
        uint256 length = 0;
        while (_task_id_for_verify_owner != 0) { _task_id_for_verify_owner >>= 8; length++; }
        require(length > 0, "invalid task id");
        require(task_id_to_owner_map[_task_id_for_verify_owner] == msg.sender && task_id_map[_task_id_for_verify_owner].task_owner == msg.sender, "You are not the task's owner");
        _;
    } 


    function remove_task(uint _task_id_for_remove) external 
        is_task_owner(_task_id_for_remove) returns(bool deleted) {
            // verification in signature:
            TaskDetails memory task_for_remove = task_id_map[_task_id_for_remove];
            bytes32 task_sig_for_verify;

            require(task_for_remove.task_status == TASK_STATUS.PENDING && task_id_to_owner_map[_task_id_for_remove] != address(0), "Task had been already CANCELED");

            for(uint i; i < tasks_sig_map[msg.sender].length; i++) {
                if(tasks_sig_map[msg.sender][i] == task_for_remove.task_signature) {
                    task_sig_for_verify = tasks_sig_map[msg.sender][i];
                    break;
                }
            }

            require(Verify(msg.sender, task_for_remove.task_message, task_sig_for_verify), 'Task is no verified');
            address owner = msg.sender; // just for prevent repeating

            // removing task proccess
            task_for_remove.task_status = TASK_STATUS.CANCELED;
            task_id_to_owner_map[_task_id_for_remove] = address(0);

            uint init_length = tasks_sig_map[owner].length;
            for(uint i; i < tasks_sig_map[owner].length; i++) {
                if(tasks_sig_map[owner][i] == task_sig_for_verify) {
                    tasks_sig_map[owner][i] = tasks_sig_map[owner][tasks_sig_map[owner].length-1];
                    tasks_sig_map[owner].pop();
                    require(tasks_sig_map[owner].length < init_length);
                    deleted = true;
                }
            } 

            require(deleted, "something went wrong");
            emit TaskCreated(owner, task_for_remove.task_id);
    }

    function complete_task(uint _task_id) external is_task_owner(_task_id) returns(bool success, uint rewarded_amount) {
        TaskDetails memory task_for_complete = task_id_map[_task_id];
        task_for_complete.task_status = TASK_STATUS.COMPLETED;

        bool user_exicted = false;
        for(uint i; i < users_list.length; i++) {
            if(users_list[i].user_address == msg.sender) {
                user_exicted = true;

                TaskToken token = TaskToken(TOKEN_CONTRACT);
                bool successed = token.transferFrom(
                    address(this), users_list[i].user_address, 10*(10**18));
                
                users_list[i].task_available -= 1;
                users_list[i].token_rewarded += 10;

                require(successed, "Some error occured in transferFrom function");
            }
        }

        require(user_exicted, "User haven't listed into user list");
        success = true;
    }
}