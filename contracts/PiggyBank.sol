// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PiggyBank {
    address public owner; // Stores the owner's address
    string public purpose; // Stores the purpose of the piggy bank
    uint256 public duration; // Stores the saving duration
    uint256 public starttime; // Stores the timestamp when the piggy bank was initialized
    bool public iswithdrawn; // Checks if the owner has withdrawn
    address public devAddress = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; // Developer address
    mapping(address => uint256) public balances; // Maps the token address to balances
    address public selectedToken; // Tracks the token chosen by the owner

    event Deposited(address indexed token, uint256 amount);
    event Withdrawn(address indexed user, address token, uint256 amount, uint256 penalty);

    constructor(
        string memory _purpose,
        uint256 _duration,
        address _token // Only one token address is passed
    ) {
        owner = msg.sender;
        purpose = _purpose;
        duration = _duration;
        starttime = block.timestamp;
        selectedToken = _token; // Set the selected token
        iswithdrawn = false;
    }

    modifier onlyOwner {
        require(owner == msg.sender, "Only the owner can perform this task");
        _;
    }

    modifier notTerminated {
        require(!iswithdrawn, "Contract is terminated");
        _;
    }

    function deposit(uint256 amount) public onlyOwner notTerminated {
        require(amount > 0, "Deposit amount must be greater than 0");

        // Transfer tokens from the sender to the contract
        IERC20(selectedToken).transferFrom(msg.sender, address(this), amount);

        // Update the balance mapping
        balances[selectedToken] += amount;

        // Emit the Deposited event
        emit Deposited(selectedToken, amount);
    }

    function timing() public view returns (bool) {
        return block.timestamp >= (starttime + duration); // Check if the stipulated time has elapsed
    }

    function Withdraw() public onlyOwner notTerminated {
        uint256 balance = balances[selectedToken];
        require(balance > 0, "No balance to withdraw");

        uint256 penaltyfee = 0;

        if (!timing()) { // Apply penalty if withdrawn before duration
            penaltyfee = (balance * 15) / 100;
            IERC20(selectedToken).transfer(devAddress, penaltyfee); // Send penalty fee to the developer
        }

        uint256 amountToTransfer = balance - penaltyfee; // Remaining balance after penalty
        IERC20(selectedToken).transfer(owner, amountToTransfer); // Transfer remaining balance to the owner

        // Update state
        balances[selectedToken] = 0;
        iswithdrawn = true;

        // Emit event
        emit Withdrawn(msg.sender, selectedToken, amountToTransfer, penaltyfee);
    }
}