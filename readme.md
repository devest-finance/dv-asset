# 📜 DvAsset Smart Contract

## 🌟 Overview
**DvAsset** is a Solidity smart contract developed to manage the lifecycle of digital tickets for tangible goods on the Ethereum blockchain. It integrates functionalities provided by the **DeVest** and **VestingToken** contracts from the DeVest library, enabling secure and efficient management of digital ticket ownership and sales.

## ✨ Features
- **Purchase Digital Tickets 🎟️**: Securely buy digital tickets representing ownership of tangible goods.
- **Transfer Ownership 🔁**: Effortlessly transfer digital tickets to other Ethereum addresses.
- **Offer for Sale 💰**: List owned digital tickets for sale at specified prices.
- **Cancel Offers ❌**: Easily cancel any existing offers for digital tickets.
- **ERC721 Compliance 🧩**: Supports ERC721 and ERC721Metadata interfaces for maximum compatibility.

## 🛠 Dependencies
This contract relies on several key external dependencies:
- **OpenZeppelin 🛡️**: For security and utility through reusable smart contracts.
- **DeVest Library 📚**: For managing vesting schedules and token vesting.
- **Hardhat 🎩**: For development environment setup, including deployment, testing, and interaction with the Ethereum blockchain.

## 🚀 Getting Started

### Prerequisites
- An Ethereum wallet loaded with Ether for contract deployment and transactions.
- Node.js and npm installed on your development machine.

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

## 🖥 Usage

- **Purchasing Tickets**: Use the `purchase` function to buy a digital ticket.
- **Transferring Tickets**: Transfer ticket ownership with the `transfer` function.
- **Offering Tickets for Sale**: List tickets on the market using the `offer` function.
- **Cancelling Sales Offers**: Withdraw tickets from the market with the `cancel` function.

Refer to the smart contract code for detailed function descriptions and further usage examples.

## 🤝 Contributing
We welcome contributions to the DvAsset project! Please feel free to fork the repository, make your changes, and submit a pull request.

## 📄 License
DvAsset is made available under the MIT License. For more details, see the LICENSE file in the project repository.
