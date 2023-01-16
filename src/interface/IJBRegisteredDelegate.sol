// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './IJBDirectory.sol';

interface IJBRegisteredDelegate {
  function deployer() external view returns (address);
}