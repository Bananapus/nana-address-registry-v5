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
    function test_addDelegate_addPayDelegateFromEOA() public {
        vm.prank(_deployer);
        address _mockValidDelegate = address(new MockValidDelegate(type(IJBPayDelegate).interfaceId));

        // Check: Is the correct event emitted?
        vm.expectEmit(true, true, true, true);
        emit DelegateAdded(_mockValidDelegate, _deployer);

        // -- transaction --
        registry.addDelegate(_deployer, 0);

        // Check: is delegate added to the mapping, with the correct deployer?
        assertTrue(registry.deployerOf(_mockValidDelegate) == _deployer);
    }

    // /**
    //  * @custom:test When adding a redemption delegate, the transaction is successful, correct event is emited and the delegate is added to the mapping
    //  */
    function test_addDelegate_addRedemptionDelegateFromEOA() public {
        vm.prank(_deployer);
        MockValidDelegate _mockValidDelegate = new MockValidDelegate(type(IJBRedemptionDelegate).interfaceId);

        // Check: Is the correct event emitted?
        vm.expectEmit(true, true, true, true);
        emit DelegateAdded(address(_mockValidDelegate), _deployer);

        // -- transaction --
        registry.addDelegate(_deployer, 0);

        // Check: is delegate added to the mapping, with the correct deployer?
        assertTrue(registry.deployerOf(address(_mockValidDelegate)) == _deployer);
    }

    /**
     * @custom:test When adding a delegate deployed from a contract, the transaction is successful, correct event
     *              is emited and the delegate is added to the mapping
     */
    function test_addDelegate_addDelegateFromContract() public {
        MockDeployer _mockDeployer = new MockDeployer();
        address _mockValidDelegate = _mockDeployer.deploy();

        // Check: Is the correct event emitted?
        vm.expectEmit(true, true, true, true);
        emit DelegateAdded(_mockValidDelegate, address(_mockDeployer));

        // -- transaction --
        registry.addDelegate(address(_mockDeployer), 1); // Nonce starts at 1 for contracts

        // Check: is delegate added to the mapping, with the correct deployer?
        assertTrue(registry.deployerOf(_mockValidDelegate) == address(_mockDeployer));
    }

    /**
     * @custom:test When adding a contract which doesn't implement IERC165, the transaction reverts
     */
    function test_addDelegate_revert_notERC165() public {
        // There is a bytecode at the _delegate address (vm.etch) but no IERC165 mocked call
        address _delegate = makeAddr("_delegate");
        vm.etch(_delegate, '69420');
        
        // Check: Is the transaction reverting?
        vm.expectRevert(abi.encodeWithSelector(JBDelegatesRegistry.JBDelegatesRegistry_incompatibleDelegate.selector));
        vm.prank(_deployer);

        // -- transaction --
        registry.addDelegate(_deployer, 1);
    }

    /**
     * @custom:test When adding a contract which doesn't implement IJBPayDelegate or IJBRedemptionDelegate, the transaction reverts
     */
    function test_addDelegate_revert_notDelegate(bytes4 _unknowInterfaceId) public {
        vm.assume(_unknowInterfaceId != type(IJBPayDelegate).interfaceId
            && _unknowInterfaceId != type(IJBRedemptionDelegate).interfaceId);

        vm.prank(_deployer);
        MockValidDelegate _mockValidDelegate = new MockValidDelegate(_unknowInterfaceId);

        // Check: Is the transaction reverting?
        vm.expectRevert(abi.encodeWithSelector(JBDelegatesRegistry.JBDelegatesRegistry_incompatibleDelegate.selector));

        // -- transaction --
        registry.addDelegate(_deployer, 0);
    }
        
    /**
     * @custom:test When adding a delegate which is not a contract (incorrect nonce or not deployed yet), the transaction reverts
     */
    function test_addDelegate_revert_notAContract(uint8 _wrongNonce) public {
        // Drop the correct nonces (0 and 1)
        vm.assume(_wrongNonce > 1);

        vm.startPrank(_deployer);
        address _mockValidDelegateNonceZero = address(new MockValidDelegate(type(IJBPayDelegate).interfaceId));
        address _mockValidDelegateNonceOne = address(new MockValidDelegate(type(IJBPayDelegate).interfaceId));
        vm.stopPrank();

        // Check: Is the transaction reverting?       
        vm.expectRevert(abi.encodeWithSelector(JBDelegatesRegistry.JBDelegatesRegistry_incompatibleDelegate.selector));
        
        // -- transaction --
        registry.addDelegate(_deployer, _wrongNonce);

        // Check: correct nonce are still working
        vm.expectEmit(true, true, true, true);
        emit DelegateAdded(address(_mockValidDelegateNonceZero), _deployer);
        registry.addDelegate(_deployer, 0);

        vm.expectEmit(true, true, true, true);
        emit DelegateAdded(address(_mockValidDelegateNonceOne), _deployer);
        registry.addDelegate(_deployer, 1);
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

contract MockValidDelegate is IERC165 {
    // this contract can mock implementing any interface, a pay delegate by default
    bytes4 _delegateType;

    constructor(bytes4 _interfaceId) {
        _delegateType = _interfaceId;
    }

    /**
     * @notice              The ierc165 supportsInterface function
     * @param interfaceId   The interface id to check
     * @return              True if the interface is supported
     */
    function supportsInterface(bytes4 interfaceId) external override view returns(bool) {
        return interfaceId == type(IERC165).interfaceId
            || interfaceId == _delegateType;
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