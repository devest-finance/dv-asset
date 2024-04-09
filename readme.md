# 📜 DvAsset Smart Contract

## 🌟 Overview
**DvAsset** is a Solidity smart contract developed for managing digital assets on EVM (Ethereum Virtual Machine) compatible blockchains. By integrating functionalities from the **DeVest** and **VestingToken** contracts within the DeVest library, DvAsset offers secure and efficient management of unique digital assets such as collectibles, tickets, and more.

## ✨ Features
- **Purchase Digital Assets 🎟️**: Securely acquire digital assets representing ownership over tangible goods.
- **Transfer Ownership 🔁**: Seamlessly transfer digital assets across Ethereum addresses.
- **Offer for Sale 💰**: List owned digital assets for sale at specified prices.
- **Cancel Offers ❌**: Easily cancel any existing offers for digital assets.
- **ERC721 Compliance 🧩**: Supports ERC721 and ERC721Metadata interfaces for maximum compatibility.

## 🛠 Dependencies
This contract relies on several key external dependencies:
- **OpenZeppelin 🛡️**: For security and utility through reusable smart contracts.
- **DeVest Library 📚**: For managing vesting schedules and token vesting.
- **Hardhat 🎩**: For development environment setup, including deployment, testing, and interaction with the Ethereum blockchain.

## 🚀 Getting Started
To begin using the DvAsset smart contracts in your projects, you have two primary options: cloning the repository or installing it directly as an npm package. Choose the method that best suits your project's needs.

### Prerequisites
- An Ethereum wallet loaded with Ether for contract deployment and transactions.
- Node.js and npm installed on your development machine.

### Cloning the Repository

For full access to the source code, examples, and tests, cloning the entire repository might be the best approach. This method is particularly useful if you plan to contribute to the project or need to adjust the contracts for your specific use case.

To clone the repository, execute the following command in your terminal:

### 📦 Install Dependencies
After cloning the DvAsset repository, navigate to the project directory and install necessary npm packages:
```bash
npm install
```

### 🛠 Compile Contracts
Use Hardhat to compile the DvAsset smart contract:
```bash
npx hardhat compile
```
### 🔧 Deploy Contracts
Deploy your contracts to a local Ethereum network or a testnet using Hardhat:
```bash
npx hardhat run scripts/deploy.js --network localhost
```

### 📝 Testing
Run the provided test suite to ensure your smart contract functions as expected:
```bash
npx hardhat test
```

### 📦 Installing as an npm Package

Alternatively, you can install DvAsset as an npm package in your project. This method is convenient for integrating DvAsset into your application without manually managing the contract files.

To install the package, use the following npm command:

```bash
npm install @devest/dv-asset
```
This command adds `@devest/dv-asset` to your project's dependencies, making the DvAsset contracts available for import and use.

#### Using DvAsset in Your Project

After installation, you can import the DvAsset contract artifacts into your JavaScript or TypeScript files as follows:
```solidity
import "@devest/dv-asset/DvAsset.sol";
```

## 🖥 Usage

- **Purchasing Tickets**: Use the `purchase` function for asset acquisition.
- **Transferring Tickets**: Transfer ownership with the `transfer` function.
- **Offering Tickets for Sale**: Use the `offer` function to list assets in the marketplace.
- **Cancelling Sales Offers**: Use the `cancel` function to retract assets from sale.

Refer to the smart contract code for detailed function descriptions and further usage examples.

## 🤝 Contributing
We welcome contributions to the DvAsset project! Please feel free to fork the repository, make your changes, and submit a pull request.

## 📄 License
DvAsset is made available under the MIT License. For more details, see the LICENSE file in the project repository.
