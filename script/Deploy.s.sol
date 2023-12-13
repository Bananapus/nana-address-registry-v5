// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@contracts/JBAddressRegistry.sol";
import "forge-std/Script.sol";

contract Deploy is Script {
    function run() public {
        vm.broadcast();
        console.log(address(new JBAddressRegistry()));
    }
}
