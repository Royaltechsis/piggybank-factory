// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PiggyBank {
    address public owner; //stores owner's address
    string public purpose; // stores thepurpose of the piggy bank 
    uint256 public duration; //stores how long user wants to lock funds
    uint256 public starttime; //stores the timestamp the piggy bank was initialized
    bool public iswithdrawn;  // checks of owner has withdrawn 
    address public devAddress; // stored dev address to pay penalty fee
    mapping(address => uint256) public balances; // maps the token address to balances

    IERC20 public usdt; // stores usdt tokens
    IERC20 public usdc; //stores  usdc tokens
    IERC20 public dai; // stores dai tokens

    event Deposited(address indexed token, uint256 amount);   
    event Withdrawn(address indexed user, address token, uint256 amount, uint256 penalty);

    constructor(
        address _owner,
        string memory _purpose,
        uint256 _duration,
        address _devaddress,
        address _usdt,
        address _usdc,
        address _dai
    ) {
        owner = _owner;
        purpose = _purpose;
        duration = _duration;
        devAddress = _devaddress;
        starttime = block.timestamp;
        usdt = IERC20(_usdt);
        usdc = IERC20(_usdc);
        dai = IERC20(_dai);
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

    

    function deposit(uint256 amount, address token) public onlyOwner notTerminated {
        require(amount > 0, "Deposit amount must be greater than 0");
        require(
            token == address(usdt) || token == address(usdc) || token == address(dai),
            "This piggy bank only supports USDT, USDC, and DAI"
        );
        IERC20(token).transferFrom(msg.sender, address(this), amount); // uses erc20 trnasfer from function to allow the contractmove funds from the owner address to the recipeint address
        balances[token] += amount;
        emit Deposited(token, amount);
    }

    function timing() public view returns (bool) {
        return block.timestamp >= (starttime + duration); // function to check if the stipulated tiem has reached forwithdrawal 
    }

    function Withdraw(address token) public onlyOwner notTerminated {
        require(
            token == address(usdt) || token == address(usdc) || token == address(dai),
            "Unsupported token"
        );
        uint256 balance = balances[token];
        require(balance > 0, "No balance to withdraw");

        uint256 penaltyfee = 0;

        if (!timing()) { // this line skips it penalty fee has been reached else 
            // Calculate penalty (15%)
            penaltyfee = (balance * 15) / 100;
            IERC20(token).transfer(devAddress, penaltyfee); // Send penaltyfee  to the dev address
        }

        
        uint256 amountToTransfer = balance - penaltyfee; // creates a new local variable to store 
        IERC20(token).transfer(owner, amountToTransfer); //uses the erc20token standard to transfer the remaining amout to the owner 

        // Update state
        balances[token] = 0;
        iswithdrawn = true;

        // Emit event
        emit Withdrawn(msg.sender, token, amountToTransfer, penaltyfee);
    }
}


//USDT: 0xdAC17F958D2ee523a2206206994597C13D831ec7
//USDC: 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
//DAI: 0x6B175474E89094C44Da98b954EedeAC495271d0F
//usdt 100000000000000000000