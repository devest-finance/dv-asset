// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@devest/contracts/DeVest.sol";
import "@devest/contracts/VestingToken.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

/**
 * @title DvAsset Contract
 * @author [Don Miguel] (DeVest 2025)
 * @notice This contract manages the lifecycle of digital tickets for a tangible good.
 *         It leverages the DeVest and VestingToken contracts from the DeVest library.
 */
contract DvAsset is Context, DeVest, ReentrancyGuard, VestingToken, IERC721, IERC721Metadata {

    // Events emitted by the contract
    event purchased(address indexed customer, uint256 indexed ticketId);
    event transferred(address indexed sender, address indexed reciver, uint256 indexed ticketId);
    event offered(address indexed owner, uint256 indexed ticketId, uint256 price);
    event canceled(address indexed owner, uint256 indexed ticketId);

    // ---
    uint256 public price;                   // current price of ticket (smallest offered)
    uint256 public totalSupply;             // total supply of tickets
    uint256 public totalPurchased = 0;      // total tickets purchased

    // --- State
    bool public preSale = true;             // while presale is active, tickets cannot be offered for sale
    bool public tradable = false;           // while tradable is active, tickets can be traded

    // Mapping of ticket IDs to owner addresses
    mapping(uint256 => address) private _tickets;

    // Mapping of owner addresses to token count
    mapping(address => uint256) private _balances;

    // Mapping from owner to list of owned token IDs
    mapping(address => uint256[]) private _ownedTokens;

    // for trading
    struct Offer {
        address owner;
        uint256 price;
    }
    mapping(uint256 => Offer) private _market; // mapping of tickets to their owners

    // Properties
    string internal _name;              // name of the tangible
    string internal _symbol;            // symbol of the tangible
    string internal _tokenURI;          // total supply of shares (10^decimals)

    /** */
    constructor(address _tokenAddress, string memory __name, string memory __symbol, string memory __tokenURI, address _factory, address _owner)
    DeVest(_owner, _factory) VestingToken(_tokenAddress) {

        _symbol =  __symbol;
        _name = __name;
        _tokenURI = __tokenURI;
    }

    /**
     *  Initialize TST as tangible
     */
    function initialize(uint tax, uint256 _totalSupply, uint256 _price, bool _tradable) public onlyOwner nonReentrant virtual{
        require(tax >= 0 && tax <= 1000, 'Invalid tax value');
        require(totalSupply >= 0 && totalSupply <= 10000, 'Max 10 decimals');

        totalSupply = _totalSupply;
        price = _price;
        tradable = _tradable;

        // set attributes
        _setRoyalties(tax, owner());
    }

    /** --------------------------------------------------------------------------------------------------- */

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function ownerOf(uint256 tokenId) public view returns (address owner) {
        return _tickets[tokenId];
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "Address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * Transfer ticket via ERC721 or ERC21 standard
     */
    function transfer(address to, uint256 ticketId) external payable takeFee {
        require(_msgSender() == ownerOf(ticketId), "Transfer caller is not owner");
        require(to != address(0), "Transfer to the zero address");

        // cancel offer if ticket is offered for sale
        if (isForSale(ticketId))
            _market[ticketId] = Offer(address(0), 0);

        _tickets[ticketId] = to;
        _balances[_msgSender()] -= 1;
        _balances[to] += 1;

        emit transferred(_msgSender(), to, ticketId);
    }

    // Purchase ticket
    function purchase(uint256 ticketId) external payable takeFee {
        require(ticketId < totalSupply, "Ticket sold out");
        require(_msgSender() != ownerOf(ticketId), "You already own this ticket");
        require(isForSale(ticketId), "Ticket not for sale");

        // check if its original ticket or ticket offered for sale
        if(_market[ticketId].owner != address(0)){
            __allowance(_msgSender(), _market[ticketId].price);
            __transferFrom(_msgSender(), _market[ticketId].owner, _market[ticketId].price);

            // remove ticket from seller
            _balances[_market[ticketId].owner] -= 1;

            // reset ticket offer
            _market[ticketId] = Offer(address(0), 0);
        } else {
            require(address(0) == ownerOf(ticketId), "Ticket not available");
            __allowance(_msgSender(), price);
            __transferFrom(_msgSender(), owner(), price);
            // assigned ticket to buyer
            totalPurchased++;
            // cancel preSale if all tickets are sold
            if (totalPurchased == totalSupply)
                preSale = false;
        }

        _tickets[ticketId] = _msgSender();
        _balances[_msgSender()] += 1;

        emit purchased(_msgSender(), ticketId);
    }
    /**
     *  Offer ticket for sales
     */
    function offer(uint256 ticketId, uint256 _price) public payable takeFee {
        require(preSale == false, "Presale is active");
        require(tradable == true, "Trading is disabled");
        require(ownerOf(ticketId) == _msgSender(), "You don't own this ticket");
        require(_price > 0, "Price must be greater than zero");
        require(isForSale(ticketId) == false, "Already for sale");

        _market[ticketId] = Offer(_msgSender(), _price);

        emit offered(_msgSender(), ticketId, _price);
    }

    /**
     * @dev Returns whether the specified token is for sale
     */
    function isForSale(uint256 ticketId) public view returns (bool) {
        return _market[ticketId].owner != address(0) || ownerOf(ticketId) == address(0);
    }

    /**
     * @dev Returns the price of the specified token
     */
    function priceOf(uint256 ticketId) public view returns (uint256) {
        return _market[ticketId].price;
    }

    /**
     *  Cancel ticket offer
     */
    function cancel(uint256 ticketId) public payable takeFee {
        require(ownerOf(ticketId) == _msgSender(), "You don't own this ticket");
        require(isForSale(ticketId), "Ticket not for sale");

        _market[ticketId] = Offer(address(0), 0);

        emit canceled(_msgSender(), ticketId);
    }

    /**
    * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory){
        return _tokenURI;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function supportsInterface(bytes4 interfaceId) external pure returns (bool){
        return interfaceId == type(IERC721).interfaceId || interfaceId == type(IERC721Metadata).interfaceId;
    }

    function approve(address to, uint256 tokenId) external {}

    function getApproved(uint256 tokenId) external view returns (address operator) {}

    function isApprovedForAll(address owner, address operator) external view returns (bool) {}

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) external {}

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external {}

    function setApprovalForAll(address operator, bool approved) external {}

    function transferFrom(address from, address to, uint256 tokenId) external {}

}
