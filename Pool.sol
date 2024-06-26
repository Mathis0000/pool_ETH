// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

/// @title Pool 
/// @author mathis

import "@openzeppelin/contracts/access/Ownable.sol";

error CollectIsFinished();
error GoalAlreadyReached();
error CollectNotFinished();
error FailedToSendEther();
error NoContribution();
error NotEnoughFunds();

contract Pool is Ownable {

    uint256 public end;
    uint256 public goal;
    uint256 public totalCollected;

    mapping (address => uint256) public contributions;

    event Contribute(address indexed contributor, uint256 amount);

    constructor(uint256 _duration, uint256 _goal)Ownable(msg.sender) {  //date de fin contrat+dure max
        end = block.timestamp + _duration;
        goal = _goal;
    }

    ///@notice contribute to the pool
    function contribute() external payable {
        if (block.timestamp >= end) {       //meme que require
            revert CollectIsFinished();
        }
        if(msg.value == 0){
            revert NotEnoughFunds();
        }

        contributions[msg.sender] += msg.value;
        totalCollected += msg.value;

        emit Contribute(msg.sender, msg.value); //pour le front
    }

    ///@notice allows the owner to withdraw
    function withdraw() external onlyOwner{
        if(block.timestamp < end || totalCollected < goal){
            revert CollectNotFinished();
        }
        (bool sent,) = msg.sender.call{value: address (this).balance}("");  //retire les gains
        if(!sent){
            revert FailedToSendEther();
        }
    }

    ///@notice allows user to get money back
    function refund() external{
        //if(block.timestamp < end){
          //  revert CollectNotFinished();
        //}
        if (totalCollected >= goal){
            revert GoalAlreadyReached();
        }
        if(contributions[msg.sender] == 0){
            revert NoContribution();
        }
        uint256 amount = contributions[msg.sender];
        contributions[msg.sender]= 0;
        totalCollected -= amount;

        (bool sent,) = msg.sender.call{value: amount}(""); //envoi
        if(!sent){
            revert FailedToSendEther();
        }
    }
}