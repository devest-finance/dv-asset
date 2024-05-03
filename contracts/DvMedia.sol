// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {DvAsset} from "./DvAsset.sol";
/**
 * @title DvMedia Contract
 * @author DeVest 2025
 * @notice This contract manages the lifecycle of digital assets for a tangible good.
 *         It leverages the DeVest and VestingToken contracts from the DeVest library.
 */
contract DvAsset is DvAsset {

    // When payment was received
    event payed(address indexed from, uint256 amount);
    event disbursed(uint256 amount);

    // Stakes
    mapping (address => uint256) internal shareholdersLevel;        // level of disburse the shareholder withdraw
    mapping (address => uint256) internal shareholdersIndex;        // index of the shareholders address

    uint256[] public disburseLevels;    // Amount disburse in each level
    uint256 internal totalDisbursed;    // Total amount disbursed (not available anymore)

    constructor(address _tokenAddress, string memory __name, string memory __symbol, string memory __tokenURI, address _factory, address _owner)
    DvAsset(_tokenAddress, __name, __symbol, __tokenURI,  _factory, _owner) VestingToken(_tokenAddress) {

        _name = __name;
        _symbol = __symbol;
        _tokenURI = __tokenURI;
    }

    /**
  *  Initialize TST as tangible
  */
    function initialize(uint tax, uint256 _totalSupply, uint256 _price, uint256 _decimals) public override onlyOwner nonReentrant {
        require(tax >= 0 && tax <= 1000, 'Invalid tax value');
        require(totalSupply >= 0 && totalSupply <= 10000, 'Max 10 decimals');

        totalSupply = _totalSupply;
        price = _price;
        preSale = true;
        tradable = true;

        // set attributes
        _setRoyalties(tax, owner());

        // stakes
        // assign to publisher all shares
        shares[_msgSender()] = (10 ** (_decimals + 2));

        // Initialize owner as only shareholder
        shareholders.push(_msgSender());
        shareholdersIndex[_msgSender()] = 0;
        shareholdersLevel[_msgSender()] = 0;
    }

    function setLicence(uint256 percentage, address owner) public override onlyOwner {
        require(percentage >= 0 && percentage <= 1000, 'Invalid amount of shares');
        require(owner != address(0), 'Invalid owner address');
        require(getShares(_msgSender()) >= amount, "Insufficient shares");
        require(_msgSender() != owner, "Can't transfer to yourself");

        // if shareholder has no shares add him as new
        if (shares[to] == 0) {
            shareholdersIndex[owner] = shareholders.length;
            shareholdersLevel[owner] = shareholdersLevel[_msgSender()];
            shareholders.push(owner);
        }

        require(shareholdersLevel[owner] == shareholdersLevel[from], "Can't swap shares of uneven levels");
        shares[owner] += amount;
        shares[_msgSender()] -= amount;

        // remove shareholder without shares
        if (shares[from] == 0){
            shareholders[shareholdersIndex[_msgSender()]] = shareholders[shareholders.length-1];
            shareholdersIndex[shareholders[shareholders.length-1]] = shareholdersIndex[_msgSender()];
            shareholders.pop();
        }
    }

    // TODO how often can this be called ??
    // Mark the current available value as disbursed
    // so shareholders can withdraw
    function disburse() public atState(States.Trading) nonReentrant {
        uint256 balance = __balanceOf(address(this));

        // check if there is balance to disburse
        if (balance > escrow){
            balance -= escrow;
            balance -= totalDisbursed;

            // Check if balance is 0, if so, nothing to disburse
            if (balance <= 0)
                return;

            disburseLevels.push(balance);
            totalDisbursed += balance;
        }

        emit disbursed(balance);
    }

    function withdraw() public payable override nonReentrant {
        require(shares[_msgSender()] > 0, 'No shares available');
        require(shareholdersLevel[_msgSender()]<disburseLevels.length, "Nothing to disburse");

        // calculate and transfer claiming amount
        uint256 amount = (shares[_msgSender()] * disburseLevels[shareholdersLevel[_msgSender()]] / _totalSupply);
        __transfer(_msgSender(), amount);

        // remove reserved amount
        totalDisbursed -= amount;

        // increase shareholders disburse level
        shareholdersLevel[_msgSender()] += 1;
    }

    // in case of purchase in pre-sale
    // royalties are not split because the owners are the only shareholder
    function _payment(address sender, address recipient, uint256 price) internal override {
        __transferFrom(sender, recipient, price);
        emit payed(_msgSender(), amount);
    }

    // in case of trade
    function _exchange(address buyer, address seller, uint256 price) internal virtual {
        // first transfer all to the contract
        __transferFrom(buyer, address(this), price);

        // calculate the _royalty and send price - royalty to the recipient
        uint256 royalty = ((getRoyalty() * price) / 1000);
        __transfer(seller, price-royalty);

        emit payed(_msgSender(), royalty);
    }

    // Function to receive Ether only allowed when contract Native Token
    receive() override external payable {}

}
