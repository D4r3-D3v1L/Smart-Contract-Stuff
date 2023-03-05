// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract Lottery is VRFConsumerBase {
    address payable public manager;
    address payable[] public players;
    uint256 public fee;
    bytes32 public keyHash;
    uint256 public randomResult;
    uint256 public MAX_PLAYERS = 5;

    constructor(
        address _vrfCoordinator,
        address _link,
        bytes32 _keyHash,
        uint256 _fee
    )
        VRFConsumerBase(_vrfCoordinator, _link)
    {
        keyHash = _keyHash;
        fee = _fee;
        manager = payable(msg.sender);
    }

    function enter() public payable {
        require(msg.value >= 1 ether, "Insufficient ETH to enter the lottery");

        players.push(payable(msg.sender));

		if (players.length == MAX_PLAYERS) {
        getRandomNumber();
    }
    }

    function getPlayers() public view returns (address payable[] memory) {
        return players;
    }

    function getRandomNumber() public returns (bytes32 requestId) {
        require(
            LINK.balanceOf(address(this)) >= fee,
            "Not enough LINK - fill contract with faucet"
        );
        return requestRandomness(keyHash, fee);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        randomResult = randomness;
        pickWinner();
    }

    function pickWinner() internal {
        require(randomResult > 0, "Random number not generated yet");
        uint256 index = randomResult % players.length;
        players[index].transfer(address(this).balance);
        players = new address payable[](0);
        randomResult = 0;
    }

    function setFee(uint256 _fee) public {
        require(msg.sender == manager, "Only the manager can update the fee");
        fee = _fee;
    }
}
