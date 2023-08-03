// SPDX-License-Identifier
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./ERC20Token.sol";

contract TaskManager {
     constructor(address _the_task_owner) public {
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
    address public OWNER_TASK;

    mapping (address => uint) public TaskByOwner;

    event TaskCreated(
        address indexed task_owner_event, uint indexed task_created_event,
        uint indexed task_id_event
    );

     function createTask(string memory _task_input, address _task_owner_input, uint _task_id_input) external virtual returns(bool) {
            require(_task_owner_input != address(0), "invalid address");
            
            task._task = _task_input;
            // task._task_id = uint(keccak256("test"));
            task._task_id = _task_id_input;
            task._task_status = TaskStatus.PENDING;
            task._task_owner = _task_owner_input;
            task._task_date_created = block.timestamp;

            TaskByOwner[task._task_owner] = task._task_id;

            emit TaskCreated(task._task_owner, task._task_date_created, task._task_id);
        }
}