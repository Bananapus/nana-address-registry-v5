// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IJBAddressRegistry {
    event AddressAdded(address indexed delegate, address indexed deployer);

    function deployerOf(address addr) external view returns (address deployer);
    function addAddressDeployedFrom(address deployer, uint256 nonce) external;
    function addAddressDeployedFrom(address deployer, bytes32 salt, bytes calldata bytecode) external;
}
