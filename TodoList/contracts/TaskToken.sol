// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TaskToken is ERC20{
    address public constant OWNER = 0xe2A6c9cFBc1571114ABCF92D5C3C3520434Ee548;
    uint public constant TOTAL_SUPPLY = 1e21;

    // bool private paused;
    address[] public users;

    mapping (address => uint) public users_balances;

    constructor() ERC20('TaskToken', 'TASK') {       
        _mint(msg.sender, TOTAL_SUPPLY);
    }
}