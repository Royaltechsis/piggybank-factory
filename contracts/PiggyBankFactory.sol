// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./PiggyBank.sol";

contract PiggyBankFactory {

     event PiggyBankCreated(address indexed piggyBankAddress, string purpose, address token);


    function getbytecode(
        string memory _purpose,
        uint256 _duration,
        address _token // Only one token address is passed
    ) public pure returns (bytes memory) {
        return abi.encodePacked(
            type(PiggyBank).creationCode,
            abi.encode(_purpose, _duration, _token)
        );
    }

    function getAddress(bytes memory bytecode, uint256 _salt) public view returns (address) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                _salt,
                keccak256(bytecode)
            )
        );

        // Cast the last 20 bytes of the hash to an address
        return address(uint160(uint256(hash)));
    }

    function Deploy(bytes memory bytecode, uint256 _salt) public {
        address addr;
        assembly {
            addr := create2(
                0, // No value sent
                add(bytecode, 0x20), // Start of the bytecode
                mload(bytecode), // Length of the bytecode
                _salt // Salt value for CREATE2
            )
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }

    }

    function createPiggyBank(
        string memory _purpose,
        uint256 _duration,
        address _token // Only one token address is passed
    ) public {
        require(
            _token == 0xdAC17F958D2ee523a2206206994597C13D831ec7 || // USDT
            _token == 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48 || // USDC
            _token == 0x6B175474E89094C44Da98b954EedeAC495271d0F, // DAI
            "Unsupported token"
        );

        // Generate bytecode for the PiggyBank contract
        bytes memory bytecode = getbytecode(_purpose, _duration, _token);

        // Calculate the deterministic address
        uint256 salt = uint256(keccak256(abi.encodePacked(_purpose, msg.sender, block.timestamp)));
        address calculatedAddress = getAddress(bytecode, salt);

        // Deploy the PiggyBank contract
        Deploy(bytecode, salt);

        // Emit an event with the created piggy bank's details
        emit PiggyBankCreated(calculatedAddress, _purpose, _token);
    }
}