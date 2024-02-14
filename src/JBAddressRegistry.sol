// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IJBAddressRegistry} from "./interfaces/IJBAddressRegistry.sol";

/// @notice This contract intended for registering deployers of Juicebox pay/redeem hooks, but does not enforce
/// adherence to an interface, and can be used for any `create`/`create2` deployer. It is the deployer's responsibility
/// to register their hook.
/// @dev This registry is intended for client integration purposes. Hook addresses are computed based on the deployer's
/// address and the nonce used to deploy the hook.
contract JBAddressRegistry is IJBAddressRegistry {
    //*********************************************************************//
    // --------------------- public stored properties -------------------- //
    //*********************************************************************//

    /// @notice Returns the deployer of a given contract, contingent on the deployer registering the deployment.
    /// @custom:param addr The address of the contract to get the deployer of.
    mapping(address addr => address deployer) public override deployerOf;

    //*********************************************************************//
    // -------------------------- constructor ---------------------------- //
    //*********************************************************************//

    constructor() {}

    //*********************************************************************//
    // ---------------------- external transactions ---------------------- //
    //*********************************************************************//

    /// @notice Add a contract address to the registry.
    /// @dev The contract must be deployed using `create`.
    /// @param deployer The address which deployed the contract.
    /// @param nonce The nonce used to deploy the contract.
    function registerAddress(address deployer, uint256 nonce) external override {
        // Compute the contract's address, assuming `create1` deployed at the given nonce.
        address hook = _addressFrom(deployer, nonce);

        // Register the contract using the computed address.
        _registerAddress(hook, deployer);
    }

    /// @notice Add a contract address to the registry.
    /// @dev The contract must be deployed using `create2`.
    /// @dev The `create2` salt is determined by the deployer's logic. The deployment bytecode can be retrieved offchain
    /// (from the deployment transaction) or onchain (with `abi.encodePacked(type(deployedContract).creationCode,
    /// abi.encode(constructorArguments))`).
    /// @param deployer The address which deployed the contract.
    /// @param salt The `create2` salt used to deploy the contract.
    /// @param bytecode The contract's deployment bytecode, including the constructor arguments.
    function registerAddress(address deployer, bytes32 salt, bytes calldata bytecode) external override {
        // Compute the contract's address based on the `create2` salt and the deployment bytecode.
        address hook =
            address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), deployer, salt, keccak256(bytecode))))));

        // Register the contract using the computed address.
        _registerAddress(hook, deployer);
    }

    //*********************************************************************//
    // ---------------------- private transactions ----------------------- //
    //*********************************************************************//

    /// @notice Register a contract's address in the `deployerOf` mapping.
    /// @param addr The deployed contract's address.
    /// @param deployer The deployer address.
    function _registerAddress(address addr, address deployer) private {
        deployerOf[addr] = deployer;

        emit AddressRegistered(addr, deployer);
    }

    /// @notice Compute the address of a contract deployed using `create1` based on the deployer's address and nonce.
    /// @dev Taken from https://ethereum.stackexchange.com/a/87840/68134 - this won't work for nonces > 2**32. If
    /// you reach that nonce please: 1) ping us, because wow 2) use another deployer.
    /// @param origin The address of the deployer.
    /// @param nonce The nonce used to deploy the contract.
    function _addressFrom(address origin, uint256 nonce) internal pure returns (address addr) {
        bytes memory data;
        if (nonce == 0x00) {
            data = abi.encodePacked(bytes1(0xd6), bytes1(0x94), origin, bytes1(0x80));
        } else if (nonce <= 0x7f) {
            data = abi.encodePacked(bytes1(0xd6), bytes1(0x94), origin, uint8(nonce));
        } else if (nonce <= 0xff) {
            data = abi.encodePacked(bytes1(0xd7), bytes1(0x94), origin, bytes1(0x81), uint8(nonce));
        } else if (nonce <= 0xffff) {
            data = abi.encodePacked(bytes1(0xd8), bytes1(0x94), origin, bytes1(0x82), uint16(nonce));
        } else if (nonce <= 0xffffff) {
            data = abi.encodePacked(bytes1(0xd9), bytes1(0x94), origin, bytes1(0x83), uint24(nonce));
        } else {
            data = abi.encodePacked(bytes1(0xda), bytes1(0x94), origin, bytes1(0x84), uint32(nonce));
        }
        bytes32 hash = keccak256(data);
        assembly {
            mstore(0, hash)
            addr := mload(0)
        }
    }
}
