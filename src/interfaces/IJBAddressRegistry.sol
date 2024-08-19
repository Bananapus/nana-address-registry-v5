// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IJBAddressRegistry {
    event AddressRegistered(address indexed addr, address indexed deployer);

    function deployerOf(address addr) external view returns (address deployer);

    function registerAddress(address deployer, uint256 nonce) external;
    function registerAddress(address deployer, bytes32 salt, bytes calldata bytecode) external;
}
