// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./PiggyBank.sol";

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

contract PiggyBankFactory {

    event PiggyBankCreated(address indexed piggyBankAddress, string purpose, address token);

    function isValidToken(address _token) internal view returns (bool) {
        try IERC20Metadata(_token).symbol() returns (string memory symbol) {
            if (
                keccak256(bytes(symbol)) == keccak256("USDT") ||
                keccak256(bytes(symbol)) == keccak256("USDC") ||
                keccak256(bytes(symbol)) == keccak256("DAI")
            ) {
                return true;
            }
        } catch {
            // If symbol() fails, the token is invalid
            return false;
        }
    
    }

    function createPiggyBank(
        string memory _purpose,
        uint256 _duration,
        address _token
    ) public {
        require(_token != address(0), "Token address cannot be zero");

        // Validate that the token is one of the supported tokens
        require(isValidToken(_token), "Unsupported token");

        // Generate bytecode for the PiggyBank contract
        bytes memory bytecode = abi.encodePacked(
            type(PiggyBank).creationCode,
            abi.encode(msg.sender, _purpose, _duration, _token)
        );

        // Calculate the deterministic address
        uint256 salt = uint256(keccak256(abi.encodePacked(_purpose, msg.sender, block.timestamp)));
        address calculatedAddress = getAddress(bytecode, salt);

        // Deploy the PiggyBank contract
        Deploy(bytecode, salt);

        // Emit an event with the created piggy bank's details
        emit PiggyBankCreated(calculatedAddress, _purpose, _token);
    }

    function getbytecode(
        address _owner,
        string memory _purpose,
        uint256 _duration,
        address _token
    ) public pure returns (bytes memory) {
        return abi.encodePacked(
            type(PiggyBank).creationCode,
            abi.encode(_owner, _purpose, _duration, _token)
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
}