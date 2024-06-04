# Bananapus Address Registry

Frontend clients need a way to verify that a Juicebox contract has a deployer they trust. `JBAddressRegistry` allows any contract deployed with `create` or `create2` to publicly register its deployer's address. Whoever deploys a contract is responsible for registering it.

<details>
  <summary>Table of Contents</summary>
  <ol>
    <li><a href="#usage">Usage</a></li>
  <ul>
    <li><a href="#install">Install</a></li>
    <li><a href="#develop">Develop</a></li>
    <li><a href="#scripts">Scripts</a></li>
    <li><a href="#deployments">Deployments</a></li>
    <li><a href="#tips">Tips</a></li>
    </ul>
    <li><a href="#repository-layout">Repository Layout</a></li>
    <li><a href="#description">Description</a></li>
  <ul>
    <li><a href="#overview">Overview</a></li>
    <li><a href="#implementation-details">Implementation Details</a></li>
    <li><a href="#risks">Risks</a></li>
    </ul>
  </ul>
  </ol>
</details>

## Usage

### Install

How to install `nana-address-registry` in another project.

For projects using `npm` to manage dependencies (recommended):

```bash
npm install @bananapus/address-registry
```

For projects using `forge` to manage dependencies (not recommended):

```bash
forge install Bananapus/nana-address-registry
```

If you're using `forge` to manage dependencies, add `@bananapus/address-registry/=lib/nana-address-registry/` to `remappings.txt`.

### Develop

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

### Scripts

For convenience, several utility commands are available in `package.json`.

| Command                           | Description                            |
| --------------------------------- | -------------------------------------- |
| `npm test`                        | Run local tests.                       |
| `npm run test:fork`               | Run fork tests (for use in CI).        |
| `npm run coverage`           | Generate an LCOV test coverage report. |

### Deployments

To deploy, you'll need to set up a `.env` file based on `.example.env`. Then run one of the following commands:

| Command                           | Description                            |
| --------------------------------- | -------------------------------------- |
| `npm run deploy:ethereum-mainnet` | Deploy to Ethereum mainnet             |
| `npm run deploy:ethereum-sepolia` | Deploy to Ethereum Sepolia testnet     |
| `npm run deploy:optimism-mainnet` | Deploy to Optimism mainnet             |
| `npm run deploy:optimism-testnet` | Deploy to Optimism testnet             |

### Tips

To view test coverage, run `npm run coverage` to generate an LCOV test report. You can use an extension like [Coverage Gutters](https://marketplace.visualstudio.com/items?itemName=ryanluker.vscode-coverage-gutters) to view coverage in your editor.

If you're using Nomic Foundation's [Solidity](https://marketplace.visualstudio.com/items?itemName=NomicFoundation.hardhat-solidity) extension in VSCode, you may run into LSP errors because the extension cannot find dependencies outside of `lib`. You can often fix this by running:

```bash
forge remappings >> remappings.txt
```

This makes the extension aware of default remappings.

## Repository Layout

The root directory contains this README, an MIT license, and config files.

The important source directories are:

```
nana-address-registry/
├── script/
│   └── Deploy.s.sol - The deployment script.
├── src/ - The contract source code.
│   ├── JBAddressRegistry.sol - The main address registry contract.
│   └── interfaces/
│       └── IJBAddressRegistry.sol - The address registry interface.
└── test/
    ├── JBAddressRegistry.t.sol - Unit tests.
    └── JBAddressRegistry_Fork.t.sol - Fork tests.
```

Other directories:

```
nana-address-registry/
├── .github/
│   └── workflows/ - CI/CD workflows.
└── broadcast/ - Deployment logs.
```

## Description

### Overview

`JBAddressRegistry` is intended for registering the deployers of Juicebox pay/redeem hooks, but does not enforce adherence to an interface, and can be used for any `create`/`create2` deployer. 

The addresses of the deployed contracts are computed deterministically based on the deployer's address, and a nonce (for `create`) or `create2` salt and deployment bytecode (for `create2`). That address is then used as a key to store the deployer's address. This allows clients to easily and trustlessly check a given hook's deployer, which can be used to help figure out whether a hook is "safe" or not, as determined by the client's developers.

_If you're having trouble understanding this contract, take a look at the [core protocol contracts](https://github.com/Bananapus/nana-core) and the [documentation](https://docs.juicebox.money/) first. If you have questions, reach out on [Discord](https://discord.com/invite/ErQYmth4dS)._


### Implementation Details

- After deploying a Juicebox pay/redeem hook, any addresses can call `JBAddressRegistry.registerAddress(address deployer, uint256 nonce)` to add it to the registry. The registry will compute and store the corresponding hook address.
- Alternatively, `JBAddressRegistry.registerAddress(address deployer, bytes32 salt, bytes calldata bytecode)` will compute and store the hook deployed from a contract using `create2`.

The registry doesn't enforce `IERC165` or the implementation of any hook interfaces, meaning it can be used for any contract deployed with `create`/`create2`.

Clients can retrieve the nonce for the contract and an EOA using `provider.getTransactionCount(address)` from `ethers.js` or `web3.eth.getTransactionCount` from `web3.js` just *before* the hook's deployment. If registering a hook later on, clients may need to manually calculate the nonce.

The `create2` salt is determined by a given deployer's logic. The deployment bytecode can be retrieved offchain (from the deployment transaction) or onchain (with `abi.encodePacked(type(deployedContract).creationCode, abi.encode(constructorArguments))`).

### Risks

Hooks have token minting access, making malicious hooks dangerous. Clients should warn project owners and users about any potential for unintended or adversarial behaviour, especially for unknown hooks.

Deployers can be exploited. Clients should still communicate risk to users.
