// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import "src/JBAddressRegistry.sol";

contract JBAddressRegistryTest is Test {
    event AddressRegistered(address indexed addr, address indexed deployer);

    address owner = makeAddr("_owner");
    address deployer = makeAddr("_deployer");
    JBAddressRegistry registry;

    function setUp() public {
        registry = new JBAddressRegistry();
    }

    /**
     * @custom:test When adding a pay hook, the transaction is successful, correct event is emited and the hook
     * is added to the mapping
     */
    function test_addHook_addAddressFromEOA(uint16 nonce) public {
        // Set the nonce of the deployer EOA (if we need to increase it)
        vm.assume(nonce >= vm.getNonce(address(deployer)));
        if (vm.getNonce(address(deployer)) != nonce) {
            vm.setNonce(address(deployer), nonce);
        }

        vm.prank(deployer);
        address mockValidAddress = address(new MockDeployment());

        // Check: Is the correct event emitted?
        vm.expectEmit(true, true, true, true);
        emit AddressRegistered(mockValidAddress, deployer);

        // Test: add the address
        registry.registerAddress(deployer, nonce);

        // Check: is address added to the mapping, with the correct deployer?
        assertTrue(registry.deployerOf(mockValidAddress) == deployer);
    }

    /**
     * @custom:test When adding a hook deployed from a contract, the transaction is successful, correct event
     *              is emited and the hook is added to the mapping
     */
    function test_addAddress_addAddressFromContract(uint16 nonce) public {
        Factory factory = new Factory();

        // Set the nonce of the deployer contract (if we need to increase it)
        vm.assume(nonce >= vm.getNonce(address(factory)));
        if (vm.getNonce(address(factory)) != nonce) {
            vm.setNonce(address(factory), nonce);
        }

        // Deploy the new address
        address mockValidAddress = factory.deploy();

        // Check: Is the correct event emitted?
        vm.expectEmit(true, true, true, true);
        emit AddressRegistered(mockValidAddress, address(factory));

        // Test: add the address
        registry.registerAddress(address(factory), nonce); // Nonce starts at 1 for contracts

        // Check: is address added to the mapping, with the correct deployer?
        assertTrue(registry.deployerOf(mockValidAddress) == address(factory));
    }

    /**
     * @custom:test When adding a hook deployed from a contract using create2, the transaction is
     *              successful, correct event is emited and the hook is added to the mapping
     */
    function test_addAddress_addAddressFromContract(bytes32 salt) public {
        vm.assume(salt != bytes32(0));
        Factory factory = new Factory();
        address mockValidAddress = factory.deploy(salt);

        // Check: Is the correct event emitted?
        vm.expectEmit(true, true, true, true);
        emit AddressRegistered(mockValidAddress, address(factory));

        // Test: add the address
        registry.registerAddress(address(factory), salt, type(MockDeployment).creationCode);

        // Check: is address added to the mapping, with the correct deployer?
        assertTrue(registry.deployerOf(mockValidAddress) == address(factory));
    }
}

// This contract doesn't do much, but is nice
contract MockDeployment {
    string _stored = "Hello, world!";

    constructor() {}

    function getFancyData() external view returns (string memory) {
        return _stored;
    }
}

contract Factory {
    function deploy() public returns (address) {
        return address(new MockDeployment());
    }

    function deploy(bytes32 _salt) public returns (address) {
        return address(new MockDeployment{salt: _salt}());
    }
}
