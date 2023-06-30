// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import '@juice-delegate-registry/JBDelegatesRegistry.sol';
import 'forge-std/Script.sol';

contract Deploy is Script {

    function run() public {

        // Change me
        IJBDelegatesRegistry _previousRegistry = IJBDelegatesRegistry(address(0));

        vm.broadcast();
        console.log(address(new JBDelegatesRegistry(_previousRegistry)));
    }
}
