// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "src/JBAddressRegistry.sol";
import "forge-std/Script.sol";

contract Deploy is Script {
    function run() public {
        vm.broadcast();
        new JBAddressRegistry();
    }
}
