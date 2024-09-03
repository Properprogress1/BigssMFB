// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract Staking {

    uint256 constant public MAX_DURATION = 60;
    uint256 constant public DAYS_IN_YEAR = 365;
    uint256 constant public FIXED_RATE = 10;

    
    struct Stake {
        address user;
        uint256 endTime;
        uint256 expectedInterest;
        bool isComplete;
    }

    receive () external payable {} 

    mapping(address => Stake[]) userStakes;

   
    function stake() external payable {
        require(msg.value > 0, "Amount must be greater than 0");
        require(msg.sender != address(0), "Invalid address");
    
        
        Stake memory newStake = Stake({
            user: msg.sender,
            endTime: block.timestamp + MAX_DURATION,
            expectedInterest: calculateInterest(msg.value, FIXED_RATE, MAX_DURATION),
            isComplete: false
        });

        userStakes[msg.sender].push(newStake);
    }

   
    function calculateInterest(uint256 _principal, uint256 _rate, uint256 _duration) internal pure returns (uint256) {
        return (_principal * _rate * _duration) / (DAYS_IN_YEAR * 100);
    }


        function claimReward(address _address, uint256 _index) external payable {
            require(userStakes[_address][_index].expectedInterest > 0, "Select a valid stake");
            Stake storage selectedStake = userStakes[_address][_index]; 
            require(block.timestamp > selectedStake.endTime, "stake is still ongoing"); 

            require(!selectedStake.isComplete, "Stake already completed"); 

            require(address(this).balance >= selectedStake.expectedInterest, "contract does not have enough funds");
            selectedStake.isComplete = true; 

            (bool success,) = msg.sender.call{value: selectedStake.expectedInterest}("");
            require(success, "Reward transfer failed");  
        }


        function getAllUserStakes(address _address) external view returns (Stake[] memory) {
            require(msg.sender != address(0), "Address zero detected"); 

            require(userStakes[_address].length > 0, "user not staked"); 

            return userStakes[_address];
        }
}
