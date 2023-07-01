// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@juice-delegate-registry/JBDelegatesRegistry.sol";

import '@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBPayDelegate.sol';
import '@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBRedemptionDelegate.sol';

import 'forge-std/Test.sol';

contract JBDelegatesRegistryTest is Test {
    event DelegateAdded(address indexed _delegate, address indexed _deployer);

    address _owner = makeAddr("_owner");
    address _deployer = makeAddr("_deployer");
    IJBDelegatesRegistry _previousRegistry = IJBDelegatesRegistry(makeAddr("_previousRegistry"));

    JBDelegatesRegistry registry;

    function setUp() public {
        registry = new JBDelegatesRegistry(_previousRegistry);

        vm.etch(address(_previousRegistry), bytes('69'));
    }

    /**
     * @custom:test When adding a pay delegate, the transaction is successful, correct event is emited and the delegate is added to the mapping
     */
    function test_addDelegate_addPayDelegateFromEOA(uint16 _nonce) public {
        // Set the nonce of the deployer EOA (if we need to increase it)
        vm.assume(_nonce >= vm.getNonce(address(_deployer)));
        if (vm.getNonce(address(_deployer)) != _nonce)
            vm.setNonce(address(_deployer), _nonce);

        vm.prank(_deployer);
        address _mockValidDelegate = address(new MockDeployment());

        // Check: Is the correct event emitted?
        vm.expectEmit(true, true, true, true);
        emit DelegateAdded(_mockValidDelegate, _deployer);

        // Test: add the delegate
        registry.addDelegate(_deployer, _nonce);

        // Check: is delegate added to the mapping, with the correct deployer?
        assertTrue(registry.deployerOf(_mockValidDelegate) == _deployer);
    }

    /**
     * @custom:test When adding a redemption delegate, the transaction is successful, correct event is emited and the delegate is added to the mapping
     */
    function test_addDelegate_addRedemptionDelegateFromEOA(uint16 _nonce) public {
        // Set the nonce of the deployer EOA (if we need to increase it)
        vm.assume(_nonce >= vm.getNonce(address(_deployer)));
        if (vm.getNonce(address(_deployer)) != _nonce)
            vm.setNonce(address(_deployer), _nonce);

        vm.prank(_deployer);
        MockDeployment _mockContract = new MockDeployment();

        // Check: Is the correct event emitted?
        vm.expectEmit(true, true, true, true);
        emit DelegateAdded(address(_mockContract), _deployer);

        // Test: add the delegate
        registry.addDelegate(_deployer, _nonce);

        // Check: is delegate added to the mapping, with the correct deployer?
        assertTrue(registry.deployerOf(address(_mockContract)) == _deployer);
    }

    /**
     * @custom:test When adding a delegate deployed from a contract, the transaction is successful, correct event
     *              is emited and the delegate is added to the mapping
     */
    function test_addDelegate_addDelegateFromContract(uint16 _nonce) public {
        Factory _factory = new Factory();

        // Set the nonce of the deployer contract (if we need to increase it)
        vm.assume(_nonce >= vm.getNonce(address(_factory)));
        if (vm.getNonce(address(_factory)) != _nonce)
            vm.setNonce(address(_factory), _nonce);

        // Deploy the new delegate
        address _mockValidDelegate = _factory.deploy();

        // Check: Is the correct event emitted?
        vm.expectEmit(true, true, true, true);
        emit DelegateAdded(_mockValidDelegate, address(_factory));

        // Test: add the delegate
        registry.addDelegate(address(_factory), _nonce); // Nonce starts at 1 for contracts

        // Check: is delegate added to the mapping, with the correct deployer?
        assertTrue(registry.deployerOf(_mockValidDelegate) == address(_factory));
    }
    
    /**
     * @custom:test When adding a delegate deployed from a contract using create2, the transaction is
     *              successful, correct event is emited and the delegate is added to the mapping
     */
    function test_addDelegate_addDelegateFromContract(bytes32 _salt) public {
        vm.assume(_salt != bytes32(0));
        Factory _factory = new Factory();
        address _mockValidDelegate = _factory.deploy(_salt);

        // Check: Is the correct event emitted?
        vm.expectEmit(true, true, true, true);
        emit DelegateAdded(_mockValidDelegate, address(_factory));

        // Test: add the delegate
        registry.addDelegateCreate2(address(_factory), _salt, type(MockDeployment).creationCode);

        // Check: is delegate added to the mapping, with the correct deployer?
        assertTrue(registry.deployerOf(_mockValidDelegate) == address(_factory));
    }

    /**
     * @custom:test When a deployer isn't found, try calling the previous registry
     */
    function test_delegateOf_retrocompatible(address _unregisteredDelegate) public {
        // Mock and expect the call to the previous registry
        vm.mockCall(address(_previousRegistry), abi.encodeCall(registry.deployerOf, (_unregisteredDelegate)), abi.encode(_deployer));
        vm.expectCall(address(_previousRegistry), abi.encodeCall(registry.deployerOf, (_unregisteredDelegate)));

        // Check: is delegate returned via the call to the previous registry?
        assertTrue(registry.deployerOf(_unregisteredDelegate) == _deployer);
    }
}

// This contract doesn't do much, but is nice
contract MockDeployment {
    string _stored = "Hello, world!";

    constructor() {
    }

    function getFancyData() external view returns(string memory) {
        return _stored;
    }
}

contract Factory {
    function deploy() public returns(address) {
        return address(new MockDeployment());
    }

    function deploy(bytes32 _salt) public returns(address) {
        return address(new MockDeployment{salt: _salt}());
    }
}