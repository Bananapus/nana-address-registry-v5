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

## Usage
Anyone can deploy this registry using the provided forge script.
In other to run this repo, you'll need [Foundry](https://book.getfoundry.sh/) and [NodeJS](https://nodejs.dev/en/learn/how-to-install-nodejs/) installed.
Install the dependencies with `npm install && git submodule update --init --force --recursive`, you should then be able
to run the tests using `forge test` or deploy a new registry using `forge script Deploy` (and the correct arguments, based on the chain and key you want to use - see the [Foundry docs](https://book.getfoundry.sh/)).

## Use-case
This registry allows frontend to easily and trustlessly query the deployer behind a given delegate. This might then used to assume a delegate as "safe" or not, based on front-end opinion.

## Risks & trade-off
A nasty delegate has a mint privilege access. It is therefore a key responsability to front-end providing informations to project owners and users on unintended/potentially adversarial behaviour, especially for unknow delegates.