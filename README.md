# Juicebox Hook Registry

Provides an accessible function linking pay/redeem hooks with their corresponding deployer addresses.

This registry uses `create` and [`create2`](https://docs.soliditylang.org/en/v0.8.23/control-structures.html#salted-contract-creations-create2) to generate a deterministic address for a hook based on a deployer address and a nonce. This address is then used as a key to store the deployer's address.

*If you're having trouble understanding this contract, take a look at the [core Juicebox contracts](https://github.com/bananapus/juice-contracts-v4) and the [documentation](https://docs.juicebox.money/) first. If you have questions, reach out on [Discord](https://discord.com/invite/ErQYmth4dS).*

## Design
### Flow
After deploying a delegate, any addresses can call `registry.addDelegate(address deployer, uint256 nonce)` to add it. The registry will compute the corresponding 
delegate address and add it. Alternatively, addDelegateCreate2(address _deployer, bytes32 _salt, bytes calldata _bytecode) can
be used to add delegate deployed from a contract, using create2. This registry doesn't inforce any delegate interface implementation (and could be used for any deployed contract).

The frontend might retrieve the correct nonce, for both contract and eoa, using  ethers `provider.getTransactionCount(address)` or web3js `web3.eth.getTransactionCount` just *before* the delegate deployment (if adding a delegate at a later time, manual nonce counting might be needed).
Create2 salt is based on the delegate deployer own internal logic while the deployment bytecode can be retrieved in the deployment transaction (off-chain) or via `abi.encodePacked(type(delegateContract).creationCode, abi.encode(constructorArguments))` (on-chain)

This registry is the second iteration and fallback on the previous version, if needed, when calling `deployerOf`.

### Contracts/interface
- JBDelegatesRegistry: the registry
- IJBDelegatesRegistry; the registry interface

## Usage
Anyone can deploy this registry using the provided forge script.
To run this repo, you'll need [Foundry](https://book.getfoundry.sh/) and [NodeJS](https://nodejs.dev/en/learn/how-to-install-nodejs/) installed.
Install the dependencies with `npm install && git submodule update --init --force --recursive`, you should then be able
to run the tests using `forge test` or deploy a new registry using `forge script Deploy` (and the correct arguments, based on the chain and key you want to use - see the [Foundry docs](https://book.getfoundry.sh/)).

## Use-case
This registry allows frontend to easily and trustlessly query the deployer behind a given delegate. This might then used to assume a delegate as "safe" or not, based on front-end opinion.

## Risks & trade-off
A nasty delegate has a mint privilege access. It is therefore a key responsability to front-end providing informations to project owners and users on unintended/potentially adversarial behaviour, especially for unknow delegates.
