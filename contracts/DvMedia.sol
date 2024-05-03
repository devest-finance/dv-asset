// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {DvAsset} from "./DvAsset.sol";
/**
 * @title DvMedia Contract
 * @author DeVest 2025
 * @notice This contract manages the lifecycle of digital assets for a tangible good.
 *         It leverages the DeVest and VestingToken contracts from the DeVest library.
 */
contract DvMedia is DvAsset {

    uint decimals;

    // When payment was received
    event payed(address indexed from, uint256 amount);
    event disbursed(uint256 amount);

    // When new licence holder is added
    event licenced(address indexed owner, uint256 percentage, uint right);

    // Stakes
    mapping (address => uint256) internal shareholdersLevel;        // level of disburse the shareholder withdraw
    mapping (address => uint256) internal shareholdersIndex;        // index of the shareholders address

    address[] internal shareholders;                                // all current shareholders
    mapping (address => uint256) internal shares;                   // shares of shareholder

    uint256[] public disburseLevels;    // Amount disburse in each level
    uint256 internal totalDisbursed;    // Total amount disbursed (not available anymore)

    // Rights
    mapping (address => uint) internal rights;

    constructor(address _tokenAddress, string memory __name, string memory __symbol, string memory __tokenURI, address _factory, address _owner)
    DvAsset(_tokenAddress, __name, __symbol, __tokenURI,  _factory, _owner) {

        _name = __name;
        _symbol = __symbol;
        _tokenURI = __tokenURI;
    }

    /**
  *  Initialize TST as tangible
  */
    function initialize(uint tax, uint256 _totalSupply, uint256 _price) public onlyOwner nonReentrant {
        require(tax >= 0 && tax <= 1000, 'Invalid tax value');
        require(totalSupply >= 0 && totalSupply <= 10000, 'Max 10 decimals');

        totalSupply = _totalSupply;
        price = _price;
        preSale = true;
        tradable = true;
    
        // set attributes
        _setRoyalties(tax, owner());

        uint8 _decimals = 2;
        // stakes
        // assign to publisher all shares
        shares[_msgSender()] = (10 ** (_decimals + 2));

        decimals = _decimals;

        // Initialize owner as only shareholder
        shareholders.push(_msgSender());
        shareholdersIndex[_msgSender()] = 0;
        shareholdersLevel[_msgSender()] = 0;

        // set royalties for owner
        setRoyalties(tax, _msgSender());
    }

    function setLicence(uint256 percentage, address owner, uint right) public onlyOwner {
        require(percentage >= 0 && percentage <= 1000, 'Invalid amount of shares');
        require(owner != address(0), 'Invalid owner address');
        require(getShares(_msgSender()) >= percentage, "Insufficient shares");
        require(_msgSender() != owner, "Can't transfer to yourself");

        // if shareholder has no shares add him as new
        if (shares[owner] == 0) {
            shareholdersIndex[owner] = shareholders.length;
            shareholdersLevel[owner] = shareholdersLevel[_msgSender()];
            shareholders.push(owner);
            rights[owner] = right;
        }

        require(shareholdersLevel[owner] == shareholdersLevel[owner], "Can't swap shares of uneven levels");
        shares[owner] += percentage;
        shares[_msgSender()] -= percentage;

        // remove shareholder without shares
        if (shares[owner] == 0){
            shareholders[shareholdersIndex[_msgSender()]] = shareholders[shareholders.length-1];
            shareholdersIndex[shareholders[shareholders.length-1]] = shareholdersIndex[_msgSender()];
            shareholders.pop();
        }
        emit licenced(owner, percentage, right);
    }

    // TODO how often can this be called ??
    // Mark the current available value as disbursed
    // so shareholders can withdraw
    function disburse() external nonReentrant {
        uint256 balance = __balanceOf(address(this));

        // check if there is balance to disburse
        balance -= totalDisbursed;

        // Check if balance is 0, if so, nothing to disburse
        if (balance <= 0)
            return;

        disburseLevels.push(balance);
        totalDisbursed += balance;

        emit disbursed(balance);
    }

    function withdraw() public payable nonReentrant {
        require(shares[_msgSender()] > 0, 'No shares available');
        require(shareholdersLevel[_msgSender()]<disburseLevels.length, "Nothing to disburse");

        // calculate and transfer claiming amount
        uint256 amount = (shares[_msgSender()] * disburseLevels[shareholdersLevel[_msgSender()]] / (10 ** (decimals + 2)));
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
        emit payed(_msgSender(), price);
    }

    // in case of trade
    function _exchange(address buyer, address seller, uint256 price) internal override virtual {
        // first transfer all to the contract
        __transferFrom(buyer, address(this), price);

        // calculate the _royalty and send price - royalty to the recipient
        uint256 royalty = ((getRoyalty() * price) / 1000);
        __transfer(seller, price-royalty);

        emit payed(_msgSender(), royalty);
    }

    // Function to receive Ether only allowed when contract Native Token
    receive() external payable {}

    // Get shares of one investor
    function getShares(address _owner) public view returns (uint256) {
            return shares[_owner];
    }
}
