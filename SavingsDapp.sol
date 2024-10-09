// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SavingsDApp {
    struct SavingsPlan {
        uint256 amount;
        uint256 startTime;
        uint256 lockTime;
        bool flexible;
        bool withdrawn;
    }

    mapping(address => SavingsPlan) public savings;
    mapping(address => uint256) public balances;
    uint256 public interestRate = 5; // Example interest rate of 5%

    event SavingsCreated(address indexed user, uint256 amount, uint256 lockTime, bool flexible);
    event SavingsWithdrawn(address indexed user, uint256 amount, uint256 interest);
    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    modifier hasSavings() {
        require(savings[msg.sender].amount > 0, "No savings found for this address");
        _;
    }

    // Users can deposit a specified amount of funds into the contract
    function depositFunds(uint256 _amount) public payable {
        require(msg.value == _amount, "The sent value must match the deposit amount");
        require(_amount > 0, "Deposit amount must be greater than zero");

        balances[msg.sender] += msg.value;

        emit Deposited(msg.sender, _amount);
    }

    // Users can withdraw their deposited funds
    function withdrawFunds(uint256 _amount) public {
        require(balances[msg.sender] >= _amount, "Insufficient balance");

        balances[msg.sender] -= _amount;
        payable(msg.sender).transfer(_amount);

        emit Withdrawn(msg.sender, _amount);
    }

    // Users can create savings with a specified lock period or flexible option
    function createSavings(uint256 _amount, uint256 _days) public {
        require(_amount > 0, "Amount should be greater than zero");
        require(_days == 30 || _days == 60 || _days == 90 || _days == 0, "Invalid time period selected");
        require(balances[msg.sender] >= _amount, "Insufficient balance to create savings");

        bool isFlexible = (_days == 0);

        savings[msg.sender] = SavingsPlan({
            amount: _amount,
            startTime: block.timestamp,
            lockTime: _days * 1 days,
            flexible: isFlexible,
            withdrawn: false
        });

        balances[msg.sender] -= _amount;

        emit SavingsCreated(msg.sender, _amount, _days, isFlexible);
    }

    // Users can withdraw their savings after the lock period or anytime for flexible savings
    function withdrawSavings() public hasSavings {
        SavingsPlan storage plan = savings[msg.sender];
        require(!plan.withdrawn, "Savings already withdrawn");

        if (!plan.flexible) {
            require(block.timestamp >= plan.startTime + plan.lockTime, "Cannot withdraw before the lock period");
        }

        uint256 interest = calculateInterest(plan.amount, plan.startTime, plan.lockTime);
        uint256 payout = plan.amount + interest;

        plan.withdrawn = true;

        payable(msg.sender).transfer(payout);

        emit SavingsWithdrawn(msg.sender, plan.amount, interest);
    }

    // Internal function to calculate interest for fixed savings
    function calculateInterest(uint256 _amount, uint256 _startTime, uint256 _lockTime) internal view returns (uint256) {
        if (_lockTime == 0) {
            return 0; // No interest for flexible savings
        }

        uint256 duration = block.timestamp - _startTime;
        uint256 applicableRate = (interestRate * duration) / 365 days;

        return (_amount * applicableRate) / 100;
    }

    // View the details of the user's savings
    function getSavingsDetails() public view returns (SavingsPlan memory) {
        return savings[msg.sender];
    }

    // View the user's deposited balance
    function getBalance() public view returns (uint256) {
        return balances[msg.sender];
    }
}
