// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC20Token.sol" as TokenContract;

contract Exercise is ERC20{  // most base like contract
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

    event adding_contribution_event(
        address indexed new_cont,
        uint time
    );

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

    function addContributers(address _addr) public virtual returns(uint conts) {
        // address[] memory users = new address[](10);
        users.push(_addr);
        emit adding_contribution_event(_addr, block.timestamp);
        return users.length;
    } 

    function efficient_remove(uint _index) public virtual {
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

// contract inheritance should sorted by most base like to most derived

contract dao_for_token is Exercise, Ownable { // most derived contract
    uint public dest_time;
    address payable public owner_dao_contract;

    event remove_user_event(address indexed remove_addr, bool remove_status);
    event received_ether(address indexed sender, uint amount);
    event send_ether(address indexed to, uint amount, bool status, uint gas);


    constructor(uint time, string memory name, string memory symbol, uint total) public 
    Exercise(name, symbol, total) {
        dest_time = time;
        owner_dao_contract = payable(msg.sender);
    }
    
    receive() external payable {
        emit received_ether(msg.sender, msg.value);
    }
    fallback() external payable {
        emit received_ether(msg.sender, msg.value);
    }
    function get_contract_balance() public view returns(uint) {
        return address(this).balance;
    }


    function addContributers(address _addr) public override(Exercise) returns(uint conts) {
        require(_addr != address(0), "invalid address");
        // address[] memory users = new address[](10);
        users.push(_addr);
        this.send_ether_to_user(payable(_addr));
        emit adding_contribution_event(_addr, block.timestamp);
        return users.length;
    } 

    function remove_user(address _addr) public onlyOwner returns(bool) {
        require(_addr != address(0), "invalid address");

        bool removed = false;
        
        for(uint i=0; i < users.length; i++) {
            if(users[i] == _addr) { 
                Exercise.efficient_remove(i);
                removed = true;
            }
        }
        
        emit remove_user_event(_addr, removed);
        return(removed);
    }

    function send_ether_to_user(address payable _user) external payable onlyOwner {
        require(_user != address(0));

        (bool sent, ) = _user.call{value : 10}("");
        emit send_ether(_user, 10, sent, gasleft());
        require(sent, "transaction failed");
    }

}