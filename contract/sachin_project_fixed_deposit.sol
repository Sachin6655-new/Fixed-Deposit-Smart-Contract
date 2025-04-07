// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FixedDeposit {

    struct Deposit {
        uint256 amount;
        uint256 startTime;
        uint256 maturityTime;
        bool isMatured;
        bool isWithdrawn;
    }

    mapping(address => Deposit[]) public userDeposits;
    uint256 public minDepositAmount = 1 ether;  // Minimum deposit amount
    uint256 public fixedDepositTerm = 365 days;  // Default term: 1 year

    event DepositCreated(address indexed user, uint256 amount, uint256 maturityTime);
    event DepositWithdrawn(address indexed user, uint256 amount);

    modifier onlyMatured(address user, uint256 index) {
        require(block.timestamp >= userDeposits[user][index].maturityTime, "Deposit has not matured yet");
        _;
    }

    modifier onlyDepositOwner(address user, uint256 index) {
        require(userDeposits[user].length > index, "Deposit does not exist");
        _;
    }

    modifier validDepositAmount(uint256 amount) {
        require(amount >= minDepositAmount, "Amount is below the minimum deposit limit");
        _;
    }

    function createDeposit(uint256 amount) external payable validDepositAmount(amount) {
        require(msg.value == amount, "Sent amount does not match the deposit amount");

        uint256 maturityTime = block.timestamp + fixedDepositTerm;
        userDeposits[msg.sender].push(Deposit({
            amount: amount,
            startTime: block.timestamp,
            maturityTime: maturityTime,
            isMatured: false,
            isWithdrawn: false
        }));

        emit DepositCreated(msg.sender, amount, maturityTime);
    }

    function withdrawDeposit(uint256 index) external onlyDepositOwner(msg.sender, index) onlyMatured(msg.sender, index) {
        Deposit storage userDeposit = userDeposits[msg.sender][index];
        
        require(!userDeposit.isWithdrawn, "Deposit already withdrawn");
        
        userDeposit.isWithdrawn = true;
        uint256 withdrawAmount = userDeposit.amount;
        payable(msg.sender).transfer(withdrawAmount);

        emit DepositWithdrawn(msg.sender, withdrawAmount);
    }

    function getDeposits(address user) external view returns (Deposit[] memory) {
        return userDeposits[user];
    }

    function getDepositDetails(address user, uint256 index) external view returns (uint256 amount, uint256 startTime, uint256 maturityTime, bool isMatured, bool isWithdrawn) {
        Deposit storage userDeposit = userDeposits[user][index];
        return (userDeposit.amount, userDeposit.startTime, userDeposit.maturityTime, userDeposit.isMatured, userDeposit.isWithdrawn);
    }
}
