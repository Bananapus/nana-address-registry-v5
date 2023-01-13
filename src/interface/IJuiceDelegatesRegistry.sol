// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IJuiceDelegatesRegistry {
    function trustedDeployers(address _deployer) external view returns (bool _isDeployer);
    function trustedJuiceDelegates(address _delegate) external view returns (address _deployer);
    function admins(address _admin) external view returns (bool _isAdmin);

    function setAdmin(address _admin, bool _isAdmin) external;
    function setDeployer(address _deployer, bool _isDeployer) external;
    function addTrustedDelegate(address _delegate) external;
}