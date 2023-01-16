// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { IJBPayDelegate } from '@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBPayDelegate.sol';
import { IJBRedemptionDelegate } from '@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBRedemptionDelegate.sol';
import { ERC165Checker } from '@openzeppelin/contracts/utils/introspection/ERC165Checker.sol';

import { IJBDelegatesRegistry } from './interfaces/IJBDelegatesRegistry.sol';
import { IJBRegisteredDelegate } from './interfaces/IJBRegisteredDelegate.sol';

/**
 * @title   JuiceDelegatesRegistry
 *
 * @notice  This contract is used to register deployers of Juicebox Delegates
 *          It is the deployer responsability to register their
 *          delegates in this registry and make sure the delegate exposes the
 *          deployer address (using IJBRegisteredDelegate and, eg, assigning msg.sender
 *          to a globale variable 'deployer' in the delegate constructor.
 *
 * @dev     Mostly for front-end integration purposes.
 *      
 */
contract JBDelegatesRegistry is IJBDelegatesRegistry {
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
     * @notice Add a delegate to the registry
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

        // If so, add it with the deployer
        address _deployer = IJBRegisteredDelegate(_delegate).deployer();
        deployerOf[_delegate] = _deployer;

        emit DelegateAdded(_delegate, _deployer);
    }
}