// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@juice-delegate-registry/JBDelegatesRegistry.sol";

import '@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBPayDelegate.sol';
import '@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBRedemptionDelegate.sol';

import '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import 'forge-std/Test.sol';

contract JBDelegatesRegistryTest is Test {
    event DelegateAdded(address indexed _delegate, address indexed _deployer);

    address _owner = makeAddr("_owner");
    address _deployer = makeAddr("_deployer");

    JBDelegatesRegistry registry;

    function setUp() public {
        registry = new JBDelegatesRegistry();
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
        address _mockValidDelegate = address(new MockValidDelegate(type(IJBPayDelegate).interfaceId));

        // Check: Is the correct event emitted?
        vm.expectEmit(true, true, true, true);
        emit DelegateAdded(_mockValidDelegate, _deployer);

        // -- transaction --
        registry.addDelegate(_deployer, _nonce);

        // Check: is delegate added to the mapping, with the correct deployer?
        assertTrue(registry.deployerOf(_mockValidDelegate) == _deployer);
    }

    // /**
    //  * @custom:test When adding a redemption delegate, the transaction is successful, correct event is emited and the delegate is added to the mapping
    //  */
    function test_addDelegate_addRedemptionDelegateFromEOA(uint16 _nonce) public {
        // Set the nonce of the deployer EOA (if we need to increase it)
        vm.assume(_nonce >= vm.getNonce(address(_deployer)));
        if (vm.getNonce(address(_deployer)) != _nonce)
            vm.setNonce(address(_deployer), _nonce);

        vm.prank(_deployer);
        MockValidDelegate _mockValidDelegate = new MockValidDelegate(type(IJBRedemptionDelegate).interfaceId);

        // Check: Is the correct event emitted?
        vm.expectEmit(true, true, true, true);
        emit DelegateAdded(address(_mockValidDelegate), _deployer);

        // -- transaction --
        registry.addDelegate(_deployer, _nonce);

        // Check: is delegate added to the mapping, with the correct deployer?
        assertTrue(registry.deployerOf(address(_mockValidDelegate)) == _deployer);
    }

    /**
     * @custom:test When adding a delegate deployed from a contract, the transaction is successful, correct event
     *              is emited and the delegate is added to the mapping
     */
    function test_addDelegate_addDelegateFromContract(uint16 _nonce) public {
        MockDeployer _mockDeployer = new MockDeployer();

        // Set the nonce of the deployer contract (if we need to increase it)
        vm.assume(_nonce >= vm.getNonce(address(_mockDeployer)));
        if (vm.getNonce(address(_mockDeployer)) != _nonce)
            vm.setNonce(address(_mockDeployer), _nonce);

        // Deploy the new delegate
        address _mockValidDelegate = _mockDeployer.deploy();

        // Check: Is the correct event emitted?
        vm.expectEmit(true, true, true, true);
        emit DelegateAdded(_mockValidDelegate, address(_mockDeployer));

        // -- transaction --
        registry.addDelegate(address(_mockDeployer), _nonce); // Nonce starts at 1 for contracts

        // Check: is delegate added to the mapping, with the correct deployer?
        assertTrue(registry.deployerOf(_mockValidDelegate) == address(_mockDeployer));
    }
    
    /**
     * @custom:test When adding a delegate deployed from a contract using create2, the transaction is
     *              successful, correct event is emited and the delegate is added to the mapping
     */
    function test_addDelegate_addDelegateFromContract(bytes32 _salt) public {
        vm.assume(_salt != bytes32(0));
        MockDeployerCreate2 _mockDeployerCreate2 = new MockDeployerCreate2();
        address _mockValidDelegate = _mockDeployerCreate2.deploy(_salt);

        // Check: Is the correct event emitted?
        vm.expectEmit(true, true, true, true);
        emit DelegateAdded(_mockValidDelegate, address(_mockDeployerCreate2));

        // -- transaction --
        registry.addDelegateCreate2(address(_mockDeployerCreate2), _salt, abi.encodePacked(type(MockValidDelegate).creationCode, abi.encode(type(IJBPayDelegate).interfaceId)));

        // Check: is delegate added to the mapping, with the correct deployer?
        assertTrue(registry.deployerOf(_mockValidDelegate) == address(_mockDeployerCreate2));
    }
}

contract MockValidDelegate {
    // this contract can mock implementing any interface, a pay delegate by default
    bytes4 _delegateType;

    constructor(bytes4 _interfaceId) {
        _delegateType = _interfaceId;
    }
}

contract MockDeployer {
    function deploy() public returns(address) {
        return address(new MockValidDelegate(type(IJBPayDelegate).interfaceId));
    }
}

contract MockDeployerCreate2 {
    function deploy(bytes32 _salt) public returns(address) {
        return address(new MockValidDelegate{salt: _salt}(type(IJBPayDelegate).interfaceId));
    }
}