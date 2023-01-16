// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import '@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBPayDelegate.sol';
import '@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBRedemptionDelegate.sol';
import '@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBRegisteredDelegate.sol';

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
    //////////////////////////////////////////////////////////////
    //                                                          //
    //                   ERRORS & EVENTS                        //
    //                                                          //
    //////////////////////////////////////////////////////////////
    
    /**
     * @notice Throws if the delegate is not compatible with the Juicebox protocol (based on ERC165)
     */
    error juiceDelegatesRegistry_incompatibleDelegate();

    /**
     * @notice Emitted when a deployed delegate is added
     */
    event DelegateAdded(address indexed _delegate, address indexed _deployer);

    //////////////////////////////////////////////////////////////
    //                                                          //
    //                  PUBLIC STATE VARIABLES                  //
    //                                                          //
    //////////////////////////////////////////////////////////////

    /**
     * @notice         Track which deployer deployed a delegate, based on a
     *                 proactive deployer update
     * @custom:params  _delegate The address of the delegate
     * @custom:returns _deployer The address of the corresponding deployer
     */
    mapping(address => address) public override deployerOf;

    //////////////////////////////////////////////////////////////
    //                                                          //
    //                     EXTERNAL METHODS                     //
    //                                                          //
    //////////////////////////////////////////////////////////////

    /**
     * @notice Add a trusted delegate to the registry
     * @param _delegate The address of the delegate
     */
    function addDelegate(address _delegate) external override {
        // Check if the delegate declares implementing a pay or redemption delegate and support this registry
        if(
            !(
                (ERC165Checker.supportsInterface(_delegate, type(IJBPayDelegate).interfaceId)
                || ERC165Checker.supportsInterface(_delegate, type(IJBRedemptionDelegate).interfaceId))
                && ERC165Checker.supportsInterface(_delegate, type(IJBRegisteredDelegate).interfaceId)
            )
        ) revert juiceDelegatesRegistry_incompatibleDelegate();

        // If so, add it with the msg.sender as the deployer
        address _deployer = IJBRegisteredDelegate(_delegate).deployer();
        deployerOf[_delegate] = _deployer;

        emit DelegateAdded(_delegate, _deployer);
    }
}