// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IJuiceDelegatesRegistry {
    function deployerOf(address _delegate) external view returns (address _deployer);
    function addDelegate(address _delegate) external;
}