// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@juice-delegate-registry/JBDelegatesRegistry.sol";

import '@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBPayDelegate.sol';
import '@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBRedemptionDelegate.sol';

import 'forge-std/Test.sol';

contract JBDelegatesRegistryTest_Fork is Test {
    address _owner = makeAddr("_owner");
    address _deployer = makeAddr("_deployer");

    address previousRegistry_deployerTest = 0xc017a3F357a1C5F5298cA40B5647d5667B73B22A;
    address previousRegistry_delegateTest = 0xF61Ca443bE449695b95baDA572fC19072330F00F;

    uint256 _blockHeight = 17580288;

    IJBDelegatesRegistry _previousRegistry = IJBDelegatesRegistry(0x7A53cAA1dC4d752CAD283d039501c0Ee45719FaC);

    JBDelegatesRegistry registry;

    function setUp() public {
        // Start a mainnet fork
        vm.createSelectFork("https://rpc.ankr.com/eth", _blockHeight);

        registry = new JBDelegatesRegistry(_previousRegistry);
    }

    /**
     * @custom:test When querying a delegate which hasn't been added to this registry, the
     *              previous deployment is queried too
     */
    function test_integration_retrocompatibility() public {
        // This delegate hasn't been added to the new registry, only the previous one
        assertEq(registry.deployerOf(previousRegistry_delegateTest), previousRegistry_deployerTest);

        // The old registry still returns the deployer
        assertEq(registry.deployerOf(previousRegistry_delegateTest), _previousRegistry.deployerOf(previousRegistry_delegateTest));
    }

    /**
     * @custom:test When adding a new delegate, it, well, workd
     */
    function test_integration_newDeployments() public {
        // Deploy a MockDeployment factory
        Factory _factory = new Factory();

        // Deploy from an EOA
        vm.prank(_deployer);
        address _mockContract = address(new MockDeployment());

        // Create1 from the factory
        address _mockDeployment1 = _factory.deploy();
        
        // Create2 from the factory
        address _mockDeployment2 = _factory.deploy(keccak256(abi.encode(696969)));

        // Test: Add the EOA (nonce 0 from the eoa)
        registry.addDelegate(_deployer, 0);

        // Test: Add the create1 (nonce 1 from the factory)
        registry.addDelegate(address(_factory), 1);

        // Test: Add the create2
        registry.addDelegateCreate2(address(_factory), keccak256(abi.encode(696969)), type(MockDeployment).creationCode);

        // Check: EOA?
        assertEq(registry.deployerOf(_mockContract), _deployer);

        // Check: create1?
        assertEq(registry.deployerOf(_mockDeployment1), address(_factory));

        // Check:create2?
        assertEq(registry.deployerOf(_mockDeployment2), address(_factory));
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