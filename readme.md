# DvAsset Smart Contract

## Overview

DvAsset is a Solidity smart contract designed to manage the lifecycle of digital tickets for tangible goods. It leverages the functionalities provided by the DeVest and VestingToken contracts from the DeVest library. This contract allows for the purchase, transfer, offering for sale, and cancellation of digital tickets representing ownership of tangible goods.

## Features

- Purchase digital tickets for tangible goods.
- Transfer ownership of digital tickets to other addresses.
- Offer digital tickets for sale at a specified price.
- Cancel existing offers for digital tickets.
- Supports ERC721 and ERC721Metadata interfaces.

## Dependencies

This contract relies on the following external dependencies:

- OpenZeppelin: Provides security and utility contracts used in the DvAsset contract.
- DeVest: Library for managing vesting schedules and token vesting.
- Ganache: Local blockchain for development and testing purposes.
- Truffle: Development framework for Ethereum smart contracts.

## Setup

To deploy and interact with the DvAsset contract locally, follow these steps:

1. Install Ganache: Download and install Ganache from the [official website](https://www.trufflesuite.com/ganache).

2. Install Truffle: Install Truffle globally using npm:
    
    ```bash
   npm install -g truffle
    ```

3. Clone the repository: Clone the DvAsset repository to your local machine:

    ```bash
    git clone https://github.com/devest-finance/dv-asset.git
    ```


4. Install Dependencies: Navigate to the project directory and install the necessary dependencies:

    ```bash
    cd dv-asset
    npm install
    ```
   
5. Compile Contracts: Compile the DvAsset contract using Truffle:

    ```bash
    truffle compile
    ```

6. Start Ganache: Launch Ganache and ensure it's running on the default port `8545`.

7. Migrate Contracts: Deploy the contracts to the local blockchain using Truffle:

    ```bash
    truffle migrate
    ```


8. Interact with Contracts: You can now interact with the deployed contracts using Truffle console or develop client applications.

## Usage

The DvAsset contract provides various functions for managing digital tickets. Here are some common interactions:

- Purchase a digital ticket: Use the `purchase` function to buy a digital ticket for a tangible good.
- Transfer ownership: Transfer ownership of a digital ticket using the `transfer` function.
- Offer for sale: Offer a digital ticket for sale at a specified price using the `offer` function.
- Cancel offer: Cancel an existing offer for a digital ticket using the `cancel` function.

Refer to the [contract documentation](httos://docs.devest.finance/) for detailed usage instructions and function descriptions.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
```
