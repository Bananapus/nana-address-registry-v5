# Juice Delegates Registry

## Summary
Provide an easy to access function linking Juicebox protocol pay and redemption delegate with their respective deployer address.

To use this registry, the delegate should implement IJBRegisteredDelegate and exposing its support via ERC165.
The most straight-forwad way of doing so is having an immutable public state variable `deployer` which is initialized as `msg.sender` in the delegate constructor.

## Design
### Flow
After deploying a delegate, any addresses can call `registry.addDelegate(newDelegate)` to add it. The registry will call the `newDelegate` to get the deployer address.

Front-end might then call the view function `registry.deployerOf(newDelegate)` to know the deployer address.

### Contracts/interface
- JBDelegatesRegistry: the registry
- IJBDelegatesRegistry; the registry interface
- IJBRegisteredDelegate: the interface to implement for a delegate wishing to be included in the registry

## Use-case
This registry allows frontend to easily and trustlessly query the deployer behind a given delegate. This might then used to assume a delegate as "safe" or not, based on front-end opinion.

## Risks & trade-off
A nasty delegate has a mint privilege access. It is therefore a key responsability to front-end providing informations to project owners and users on unintended/potentially adversarial behaviour, especially for unknow delegates.