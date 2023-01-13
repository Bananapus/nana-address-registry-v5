// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import '@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBPayDelegate.sol';
import '@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBRedemptionDelegate.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165Checker.sol';
import './interface/IJuiceDelegatesRegistry.sol';

/**
 * @title   JuiceDelegatesRegistry
 *
 * @notice  This contract is used to register Juicebox Delegates
 *          that are trusted to be used by Juicebox projects.
 *          It is the deployer responsability to register their
 *          delegates in this registry.
 * @dev     Mostly for front-end integration purposes.
 *      
 */
contract JuiceDelegatesRegistry is IJuiceDelegatesRegistry {
    
    /**
     * @notice Throws if the delegate is not compatible with the Juicebox protocol (based on ERC165)
     */
    error juiceDelegatesRegistry_incompatibleDelegate();

    /**
     * @notice Throws if the caller is not authorized to call the function
     */
    error juiceDelegatesRegistry_authError();

    /**
     * @notice Emitted when a deployed delegate is added
     */
    event DelegateAdded(address indexed _delegate, address indexed _deployer);

    /**
     * @notice         The deployer addresses which are recognized as trusted
     * @custom:params  _deployer The address of the deployer
     * @custom:returns _isDeployer Whether the address is a trusted deployer
     */
    mapping(address => bool) public override trustedDeployers;

    /**
     * @notice         Track which deployer deployed a delegate, based on a
     *                 proactive deployer update
     * @custom:params  _delegate The address of the delegate
     * @custom:returns _deployer The address of the corresponding deployer
     */
    mapping(address => address) public override trustedJuiceDelegates;

    /**
     * @notice         Access control for adding/removing deployers.
     * @custom:params  _admin The address of the deployer
     * @custom:returns _isAdmin Whether the address is a trusted deployer
     */
    mapping(address => bool) public override admins;

    /**
     * @notice Modifier to restrict access to trusted deployers
     */
    modifier onlyDeployer() {
        if(!trustedDeployers[msg.sender]) revert juiceDelegatesRegistry_authError();
        _;
    }

    /**
     * @notice Modifier to restrict access to administrators of this contract
     */
    modifier onlyAdmin() {
        if(!admins[msg.sender]) revert juiceDelegatesRegistry_authError();
        _;
    }

    /**
     * @notice Constructor: grant msg.sender admin access
     */
    constructor() {
        admins[msg.sender] = true;
    }

    /**
     * @notice Set the admin status of an address
     * @param _admin The address to set the admin status of
     * @param _isAdmin Whether the address is an admin
     */
    function setAdmin(address _admin, bool _isAdmin) external override onlyAdmin {
        admins[_admin] = _isAdmin;
    }

    /**
     * @notice Set the deployer status of an address
     * @param _deployer The address to set the deployer status of
     * @param _isDeployer Whether the address is a deployer
     */
    function setDeployer(address _deployer, bool _isDeployer) external override onlyAdmin {
        trustedDeployers[_deployer] = _isDeployer;
    }

    /**
     * @notice Add a trusted delegate to the registry
     * @param _delegate The address of the delegate
     */
    function addTrustedDelegate(address _delegate) external override onlyDeployer {
        // Check if the delegate declares support for the IJBPayDelegate or IJBRedemptionDelegate interface
        if( !(ERC165Checker.supportsInterface(_delegate, type(IJBPayDelegate).interfaceId)
        || ERC165Checker.supportsInterface(_delegate, type(IJBRedemptionDelegate).interfaceId)) )
            revert juiceDelegatesRegistry_incompatibleDelegate();

        // If so, add it with the msg.sender as the deployer
        trustedJuiceDelegates[_delegate] = msg.sender;

        emit DelegateAdded(_delegate, msg.sender);
    }
}