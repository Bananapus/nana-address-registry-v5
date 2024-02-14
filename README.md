# Bananapus Address Registry

Provides an accessible function linking pay/redeem hooks with their corresponding deployer addresses.

This registry uses `create1` and [`create2`](https://docs.soliditylang.org/en/v0.8.23/control-structures.html#salted-contract-creations-create2) to generate a deterministic address for a hook based on a deployer address and a nonce. That address is then used as a key to store the deployer's address. This allows clients to easily and trustlessly check a given hook's deployer, which can be used to help figure out whether a hook is "safe" or not, as determined by the client's developers.

Although `JBAddressRegistry` is intended for registering deployers of Juicebox pay/redeem hooks, it does not enforce adherence to an interface, and can be used to track any `create1`/`create2` deployer. It is the deployer's responsibility to register their contracts.

_If you're having trouble understanding this contract, take a look at the [core protocol contracts](https://github.com/Bananapus/nana-core) and the [documentation](https://docs.juicebox.money/) first. If you have questions, reach out on [Discord](https://discord.com/invite/ErQYmth4dS)._

## Install

For `npm` projects (recommended):

```bash
npm install @bananapus/address-registry
```

For `forge` projects (not recommended):

```bash
forge install Bananapus/nana-address-registry
```

Add `@bananapus/address-registry/=lib/nana-address-registry/` to `remappings.txt`.

## Develop

`nana-address-registry` uses the [Foundry](https://github.com/foundry-rs/foundry) development toolchain for builds, tests, and deployments. To get set up, install [Foundry](https://github.com/foundry-rs/foundry):

```bash
curl -L https://foundry.paradigm.xyz | sh
```

You can download and install dependencies with:

```bash
forge install
```

If you run into trouble with `forge install`, try using `git submodule update --init --recursive` to ensure that nested submodules have been properly initialized.

Some useful commands:

| Command               | Description                                         |
| --------------------- | --------------------------------------------------- |
| `forge build`         | Compile the contracts and write artifacts to `out`. |
| `forge fmt`           | Lint.                                               |
| `forge test`          | Run the tests.                                      |
| `forge build --sizes` | Get contract sizes.                                 |
| `forge coverage`      | Generate a test coverage report.                    |
| `foundryup`           | Update foundry. Run this periodically.              |
| `forge clean`         | Remove the build artifacts and cache directories.   |

To learn more, visit the [Foundry Book](https://book.getfoundry.sh/) docs.

## Scripts

For convenience, several utility commands are available in `package.json`.

| Command                           | Description                            |
| --------------------------------- | -------------------------------------- |
| `npm test`                        | Run local tests.                       |
| `npm run test:fork`               | Run fork tests (for use in CI).        |
| `npm run coverage:lcov`           | Generate an LCOV test coverage report. |
| `npm run deploy:ethereum-mainnet` | Deploy to Ethereum mainnet             |
| `npm run deploy:ethereum-sepolia` | Deploy to Ethereum Sepolia testnet     |
| `npm run deploy:optimism-mainnet` | Deploy to Optimism mainnet             |
| `npm run deploy:optimism-testnet` | Deploy to Optimism testnet             |

## Notes

- After deploying a hook, any addresses can call `JBAddressRegistry.registerAddress(address deployer, uint256 nonce)` to add it to the registry. The registry will compute and store the corresponding hook address.
- Alternatively, `JBAddressRegistry.registerAddress(address deployer, bytes32 salt, bytes calldata bytecode)` will compute and store the hook deployed from a contract using `create2`.

The registry doesn't enforce `IERC165` or the implementation of any hook interfaces, meaning it could be used for any contract deployed with `create`/`create2`.

Clients can retrieve the nonce for the contract and an EOA using `provider.getTransactionCount(address)` from `ethers.js` or `web3.eth.getTransactionCount` from `web3.js` just *before* the hook's deployment. If registering a hook later on, clients may need to manually calculate the nonce.

The `create2` salt is determined by a given deployer's logic. The deployment bytecode can be retrieved offchain (from the deployment transaction) or onchain (with `abi.encodePacked(type(deployedContract).creationCode, abi.encode(constructorArguments))`).

This registry is the second iteration and will fall back to the previous version as needed when calling `deployerOf`.

## Risk

Malicious hooks have a token minting access. Clients should provide comprehensive information to project owners and users on the potential for unintended or adversarial behaviour, especially for unknown hooks.
