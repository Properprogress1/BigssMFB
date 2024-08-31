// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract Staking {

    uint256 constant public MAX_DURATION = 60;
    uint256 constant public DAYS_IN_YEAR = 365;
    uint256 constant public FIXED_RATE = 10;

    mapping(address => uint256) public balances;

    

    struct Stake {
        address user;
        uint256 endTime;
        uint256 expectedInterest;
        bool isComplete;
    }

    receive () external payable{}

    // Stake[] stakes;
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
            Stake storage selectedStake = userStakes[_address][_index]; //This line retrieves the specific stake from the user's array of stakes using the provided index. The stake is stored in a local variable named selectedStake.
            require(block.timestamp > selectedStake.endTime, "stake is still ongoing"); //This line checks if the current block timestamp is greater than the stake's end time 

            require(!selectedStake.isComplete, "Stake already completed"); //This line ensures that the stake has not already been completed. 

            require(address(this).balance >= selectedStake.expectedInterest, "contract does not have enough funds");
            selectedStake.isComplete = true; // This line checks whether the contract's balance is sufficient to pay out the expected interest for the stake. 

            (bool success,) = msg.sender.call{value: selectedStake.expectedInterest}("");
            require(success, "Reward transfer failed");  //This line marks the stake as completed by setting the isComplete flag to true.
        }


        function getAllUserStakes(address _address) external view returns (Stake[] memory) {
            require(msg.sender != address(0), "Address zero detected"); //This line attempts to transfer the expected interest (in Ether) to the user who called the function (msg.sender)

            require(userStakes[_address].length > 0, "user not available"); // this line checks whether the transfer was successful. If the transfer failed, the transaction is reverted with the error message "Reward transfer failed"

            return userStakes[_address];
        }
}
