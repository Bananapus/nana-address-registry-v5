// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import '@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBPayDelegate.sol';
import '@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBRedemptionDelegate.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165Checker.sol';

contract JuiceDelegatesRegistry {
    error juiceDelegatesRegistry_incompatibleDelegate();
    error juiceDelegatesRegistry_authError();

    mapping(address => bool) public trustedDeployers;

    // delegate => deployer
    mapping(address => address) public trustedJuiceDelegates;

    mapping(address => bool) public admins;

    modifier onlyDeployer() {
        if(!trustedDeployers[msg.sender]) revert juiceDelegatesRegistry_authError();
        _;
    }

    modifier onlyAdmin() {
        if(!admins[msg.sender]) revert juiceDelegatesRegistry_authError();
        _;
    }

    function setAdmin(address _admin, bool _isAdmi) external onlyAdmin {
        admins[_admin] = _isAdmi;
    }

    function setDeployer(address _deployer, bool _isDeployer) external onlyAdmin {
        trustedDeployers[_deployer] = _isDeployer;
    }

    function addTrustedDelegate(address _delegate) external onlyDeployer {
        if( !(ERC165Checker.supportsInterface(_delegate, type(IJBPayDelegate).interfaceId)
        || ERC165Checker.supportsInterface(_delegate, type(IJBRedemptionDelegate).interfaceId)) )
            revert juiceDelegatesRegistry_incompatibleDelegate();

        trustedJuiceDelegates[_delegate] = msg.sender;
    }
}
