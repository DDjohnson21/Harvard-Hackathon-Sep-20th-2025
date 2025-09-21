# Flare Smart Contracts Periphery

This package contains ABIs and addresses for smart contracts deployed on [Flare networks](https://dev.flare.network/network/solidity-reference):

- Flare Mainnet
- Songbird Canary Network
- Flare Testnet Coston2
- Songbird Testnet Coston

## Installation

```bash
npm install @flarenetwork/flare-periphery-contract-artifacts
# or
yarn add @flarenetwork/flare-periphery-contract-artifacts
```

## Features

### Top Level Exports

#### ABI Access Functions

<!-- FIXME:(FilipS) This is probably not correct?! Both functions currently return the same ABI. -->

- `nameToAbi(name: string, network: string): any` - Get full smart contract functionality.
- `interfaceToAbi(name: string, network: string): any` - Interact with the contract's public API.

Both functions return an ABI array. The `network` parameter must be one of:

- `"flare"`
- `"songbird"`
- `"coston2"`
- `"coston"`

```typescript
import { nameToAbi, interfaceToAbi } from "@flarenetwork/flare-periphery-contract";

const fullAbi = nameToAbi("FtsoManager", "flare");
const interfaceAbi = interfaceToAbi("IFtsoManager", "flare");
```

#### Address Resolution

- `nameToAddress(name: string, network: string, provider: ethers.JsonRpcApiProvider): Promise<string>`
- `namesToAddresses(names: string[], network: string, provider: ethers.JsonRpcApiProvider): Promise<string[]>`

These functions fetch contract addresses from the on-chain FlareContractRegistryLibrary.

```typescript
import { nameToAddress } from "@flarenetwork/flare-periphery-contract-artifacts";
import { ethers } from "ethers";

const provider = new ethers.JsonRpcProvider("https://flare-api.flare.network/ext/C/rpc");
const address = await nameToAddress("FtsoManager", "flare", provider);
```

#### Constants

- `FlareContractRegistryAddress`: Hardcoded registry address (same for all chains)

### Network-Specific Namespaces

Each network (`flare`, `songbird`, `coston2`, `coston`) exports:

#### 1. Products

Access contract information through `.ContractName` syntax:

```typescript
import { flare } from "@flarenetwork/flare-periphery-contract-artifacts";

const ftsoManager = flare.products.FtsoManager;
console.log(ftsoManager.name); // Contract name
console.log(ftsoManager.interface); // Interface name
console.log(ftsoManager.abi); // Contract ABI

// Get deployed address
const address = await ftsoManager.getAddress(provider);
```

#### 2. Interface ABIs

Access interface ABIs using `.InterfaceName` syntax:

```typescript
import { flare } from "@flarenetwork/flare-periphery-contract-artifacts";

const abi = flare.interfaceAbis.IFtsoManager;
```

#### 3. Network-Specific ABI Functions

It is same as top-level functions but with the pre-set network:

```typescript
import { flare } from "@flarenetwork/flare-periphery-contract-artifacts";

// Network already known
const abi = flare.nameToAbi("FtsoManager");
const iAbi = flare.interfaceToAbi("IFtsoManager");
```

## Support

For issues and feature requests, please visit our [GitHub repository](https://github.com/flare-foundation/flare-smart-contracts-periphery).
