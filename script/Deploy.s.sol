// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "lib/forge-std/src/Script.sol";

import "src/JBAddressRegistry.sol";

contract Deploy is Script {
    function run() public {
        vm.broadcast();
        new JBAddressRegistry();
    }
}
