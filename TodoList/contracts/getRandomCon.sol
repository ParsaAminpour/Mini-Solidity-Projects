// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
contract GetRandom is VRFConsumerBase {
    bytes32 internal keyHash;
    uint internal fee;
    uint randomResult;  
    constructor() VRFConsumerBase(
        0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625,
        0x779877A7B0D9E8603169DdbD7836e478b4624789)
    {
        keyHash = 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c;
        fee = 0.25 * (10**18);
    }

    function getRandomNumberFromChainlinkVRF() public returns(bytes32 requestId) {
        require(LINK.balanceOf(address(this)) > fee, "Unsufficient LINK balance from contract");
        return requestRandomness(keyHash, fee);
    }

    function fulfillRandomness(bytes32 _requestId, uint randomness) internal override {
        randomResult = randomness;
    }

    function get_random_number() public view returns(uint) {
        return randomResult;
    }

}