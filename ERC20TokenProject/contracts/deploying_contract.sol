// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract exercise is ERC20{
    address public constant OWNER = 0xe2A6c9cFBc1571114ABCF92D5C3C3520434Ee548;
    // bool private paused;
    address[] public users;
    struct User {
        address _owner; uint _balance; uint _joined_date; 
    }
    User[] public users_details; 
    User public user;
    mapping (address => uint) public users_balances;
    // address[10] public users;

    enum Status { paused, maintane, stopped }
    Status private status;
    constructor(string memory name, string memory symbol,uint256 total_supply) public
        ERC20(name, symbol) {       
        if(msg.sender == OWNER) {
            status = Status.maintane;
        } else { status = Status.stopped; }
        users.push(msg.sender);

        user._owner = msg.sender;
        user._balance = address(msg.sender).balance;
        user._joined_date = block.timestamp;

        // users_details.push(User(msg.sender, address(msg.sender).balance, block.timestamp));
        users_details.push(user);
        users_balances[user._owner] = user._balance;

        _mint(msg.sender, total_supply);
    }

    modifier ContractIsPaused() {
        require(status == Status.maintane);
        _;
    }

    function getCallerAndStatus() public view ownerIs returns(address, Status) {
        require(msg.sender != address(0), 'invalid address');

        return (msg.sender, status); 
    }

    function getContractStatus() public view returns(Status){
        (, Status _status) = getCallerAndStatus();
        return _status;
    }

    function addContributers(address _addr) public returns(uint conts) {
        // address[] memory users = new address[](10);
        users.push(_addr);
        return users.length;
    } 

    function efficient_remove(uint _index) public returns(uint) {
        require(_index < users.length, 'the index is overflow');

        users[_index] = users[users.length];
        users.pop();
    }

    error address_error();
    function test_owner(address _addr) public returns(address) {
        if(_addr != msg.sender) {
            revert address_error();
        }
        assert(msg.sender == OWNER);   
    }

    modifier ownerIs() {
        require(msg.sender == OWNER, 'only the owner could execute this function');
        _;
    }


    function test_function(uint _val) public ownerIs returns(bool) {
        return _val == 0 ? true : false;
    }
}