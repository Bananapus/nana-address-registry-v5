// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import '@juice-delegate-registry/JBDelegatesRegistry.sol';
import 'forge-std/Script.sol';

contract Deploy is Script {

    function run() public {
        IJBDelegatesRegistry _previousRegistry;
        
        // Mainnet
        if(block.chainid == 1)
        _previousRegistry = IJBDelegatesRegistry(0x7A53cAA1dC4d752CAD283d039501c0Ee45719FaC);

        // Goerli
        else if(block.chainid == 5)
        _previousRegistry = IJBDelegatesRegistry(0xCe3Ebe8A7339D1f7703bAF363d26cD2b15D23C23);

        // Sepolia
        else if(block.chainid == 1337)
        _previousRegistry = IJBDelegatesRegistry(address(0));

        vm.broadcast();
        console.log(address(new JBDelegatesRegistry(_previousRegistry)));
        console.log(address(_previousRegistry));
    }
}
