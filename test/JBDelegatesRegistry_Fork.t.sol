// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import "src/JBAddressRegistry.sol";

contract JBAddressRegistryTest_Fork is Test {
    address owner = makeAddr("_owner");
    address deployer = makeAddr("_deployer");

    uint256 blockHeight = 17_580_288;

    JBAddressRegistry registry;

    function setUp() public {
        // Start a mainnet fork
        vm.createSelectFork("https://rpc.ankr.com/eth", blockHeight);

        registry = new JBAddressRegistry();
    }

    /**
     * @custom:test When adding a new hook, it, well, workd
     */
    function test_integration_newDeployments() public {
        // Deploy a MockDeployment factory
        Factory factory = new Factory();

        // Deploy from an EOA
        vm.prank(deployer);
        address mockContract = address(new MockDeployment());

        // Create1 from the factory
        address mockDeployment1 = factory.deploy();

        // Create2 from the factory
        address mockDeployment2 = factory.deploy(keccak256(abi.encode(696_969)));

        // Test: Add the EOA (nonce 0 from the eoa)
        registry.registerAddress(deployer, 0);

        // Test: Add the create1 (nonce 1 from the factory)
        registry.registerAddress(address(factory), 1);

        // Test: Add the create2
        registry.registerAddress(address(factory), keccak256(abi.encode(696_969)), type(MockDeployment).creationCode);

        // Check: EOA?
        assertEq(registry.deployerOf(mockContract), deployer);

        // Check: create1?
        assertEq(registry.deployerOf(mockDeployment1), address(factory));

        // Check:create2?
        assertEq(registry.deployerOf(mockDeployment2), address(factory));
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
