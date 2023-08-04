// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./deploying_contract.sol";

interface IToken {  // FirstOff we should deploy the Token contract and use this contract via its interface with contract address like IToken(addr).test()
    function mintMinerReward() external;
    function addContributers() external returns(uint);
}

contract TaskManager is Ownable {
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

    // creating task based on Taskdetail struct
     function createTask(string memory _task_input, address _task_owner_input, uint _task_id_input) external 
        virtual returns(bool) {
            require(_task_owner_input != address(0), "invalid address");
            
            task._task = _task_input;
            // task._task_id = uint(keccak256("test"));
            task._task_id = _task_id_input;
            task._task_status = TaskStatus.PENDING;
            task._task_owner = _task_owner_input;
            task._task_date_created = block.timestamp;

            TaskByOwner[task._task_owner] = task._task_id;
            tasks_list_struct.push(task);

            emit TaskCreated(task._task_owner, task._task_date_created, task._task_id);
            assert(TaskByOwner[_task_owner_input] == _task_id_input);
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
    function completeTask(address _token_reward_contract_addr, uint _task_id_for_complete) public returns(bool success) {
        require(!(_task_id_for_complete > tasks_list_struct.length && TaskByOwner[msg.sender] != _task_id_for_complete));

        if(this.removeTask(_task_id_for_complete) == true) {
            (bool success, bytes memory data) = _token_reward_contract_addr.call{value:100, gas:5000}
            (
                abi.encodeWithSignature("_beforeTokenTransfer(address,address,uint)", 
                    Exercise(_token_reward_contract_addr).who_is_owner() , msg.sender, 100)
            );
        }
    }
}