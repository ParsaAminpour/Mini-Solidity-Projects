// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "OpenZeppelin/openzeppelin-contracts@4.9.2/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract KIA is ERC20{
    constructor(string memory name, string memory symbol,uint256 total_supply) public
        ERC20(name, symbol) {
        _mint(msg.sender, total_supply);
    }
}