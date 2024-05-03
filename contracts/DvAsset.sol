// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@devest/contracts/DeVest.sol";
import "@devest/contracts/VestingToken.sol";
/**
 * @title DvAsset Contract
 * @author DeVest 2025
 * @notice This contract manages the lifecycle of digital assets for a tangible good.
 *         It leverages the DeVest and VestingToken contracts from the DeVest library.
 */
contract DvAsset is Context, DeVest, ReentrancyGuard, VestingToken, IERC721, IERC721Metadata {

    // Events emitted by the contract
    event purchased(address indexed customer, uint256 indexed assetId);
    event transferred(address indexed sender, address indexed reciver, uint256 indexed assetId);
    event offered(address indexed owner, uint256 indexed assetId, uint256 price);
    event canceled(address indexed owner, uint256 indexed assetId);
    event issued(address indexed sender, uint256 price, uint256 assetId, string referenceId);

    // ---
    uint256 public price;                   // current price of asset (smallest offered)
    uint256 public totalSupply;             // total supply of assets
    uint256 public totalPurchased = 0;      // total assets purchased

    // --- State
    bool public preSale = true;             // while presale is active, assets cannot be offered for sale
    bool public tradable = false;           // while tradable is active, assets can be traded
    bool public direct = false;             // while direct is active, assets can be purchased directly at a set price, deactivates presale

    // Mapping of asset IDs to owner addresses
    mapping(uint256 => address) private _assets;

    // Mapping of owner addresses to token count
    mapping(address => uint256) private _balances;

    // Mapping from owner to list of owned token IDs for enumeration
    mapping(address => mapping(uint256 => uint256)) private _ownedAssets;

    // Mapping from token ID to index in the owner's list of tokens
    mapping(uint256 => uint256) private _ownedAssetsIndex;

    // Mapping from referenceId to owner
    mapping(string => address) private ownerByExternalReferenceId;

    // for trading
    struct Offer {
        address owner;
        uint256 price;
    }

    mapping(uint256 => Offer) private _market; // mapping of assets to their owners

    // Properties
    string internal _name;              // name of the tangible
    string internal _symbol;            // symbol of the tangible
    string internal _tokenURI;          // total supply of shares (10^decimals)

    /** */
    constructor(address _tokenAddress, string memory __name, string memory __symbol, string memory __tokenURI, address _factory, address _owner)
    DeVest(_owner, _factory) VestingToken(_tokenAddress) {

        _name = __name;
        _symbol = __symbol;
        _tokenURI = __tokenURI;
    }

    /**
     *  Initialize TST as tangible
     */
    function initialize(uint tax, uint256 _totalSupply, uint256 _price, bool _tradable, bool _direct) public onlyOwner nonReentrant virtual {
        require(tax >= 0 && tax <= 1000, 'Invalid tax value');
        require(totalSupply >= 0 && totalSupply <= 10000, 'Max 10 decimals');

        totalSupply = _totalSupply;
        price = _price;
        tradable = _tradable;
        direct = _direct;
        preSale = !_direct;

        // set attributes
        _setRoyalties(tax, owner());
    }

    /** --------------------------------------------------------------------------------------------------- */

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function ownerOf(uint256 assetId) public view returns (address owner) {
        return _assets[assetId];
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "Address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * Transfer asset via ERC721 or ERC21 standard
     */
    function transfer(address to, uint256 assetId) external payable takeFee {
        require(_msgSender() == ownerOf(assetId), "Transfer caller is not owner");
        require(to != address(0), "Transfer to the zero address");

        // cancel offer if asset is offered for sale
        if (isForSale(assetId))
            _market[assetId] = Offer(address(0), 0);

        _assets[assetId] = to;
        _balances[_msgSender()] -= 1;
        _balances[to] += 1;

        emit transferred(_msgSender(), to, assetId);
    }

    /**
     *  Purchase and mint asset directly
     */
    function issue(string memory referenceId, uint256 _price) external payable takeFee {
        require(direct == true, "Direct purchase is disabled");
        require(preSale == false, "Presale is active");
        require(tradable == false, "Trading is enabled");
        require(_msgSender() != ownerOf(totalPurchased + 1), "You already own this asset");

        __allowance(_msgSender(), _price);
        __transferFrom(_msgSender(), owner(), _price);

        // assigned asset to buyer
        totalPurchased++;
        addToOwnedAssets(_msgSender(), totalPurchased);

        _assets[totalPurchased] = _msgSender();
        _balances[_msgSender()] += 1;
        ownerByExternalReferenceId[referenceId] = _msgSender();

        emit issued(_msgSender(), _price, totalPurchased, referenceId);
    }

    // Purchase asset
    function purchase(uint256 assetId) external payable takeFee virtual{
        require(direct == false, "Direct purchase is enabled");
        require(assetId < totalSupply, "Asset sold out");
        require(_msgSender() != ownerOf(assetId), "You already own this asset");
        require(isForSale(assetId), "Asset not for sale");

        // check if its original asset or asset offered for sale
        if (_market[assetId].owner != address(0)) {
            __allowance(_msgSender(), _market[assetId].price);
            _exchange(_msgSender(), _market[assetId].owner, _market[assetId].price);

            // remove asset from seller
            removeFromOwnedTokens(_market[assetId].owner, assetId);
            _balances[_market[assetId].owner] -= 1;

            // reset asset offer
            _market[assetId] = Offer(address(0), 0);
        } else {
            require(address(0) == ownerOf(assetId), "Asset not available");
            __allowance(_msgSender(), price);
            _payment(_msgSender(), owner(), price);
            // assigned asset to buyer
            totalPurchased++;
            // cancel preSale if all assets are sold
            if (totalPurchased == totalSupply)
                preSale = false;
        }
        addToOwnedAssets(_msgSender(), assetId);
        _assets[assetId] = _msgSender();
        _balances[_msgSender()] += 1;

        emit purchased(_msgSender(), assetId);
    }

    function _exchange(address buyer, address seller, uint256 price) internal virtual {
        __transferFrom(buyer, seller, price);
    }

    function _payment(address sender, address recipient, uint256 price) internal virtual {
        __transferFrom(sender, recipient, price);
    }

    /**
     *  Offer asset for sales
     */
    function offer(uint256 assetId, uint256 _price) public payable takeFee {
        require(preSale == false, "Presale is active");
        require(tradable == true, "Trading is disabled");
        require(direct == false, "Direct purchase is enabled");
        require(ownerOf(assetId) == _msgSender(), "You don't own this asset");
        require(_price > 0, "Price must be greater than zero");
        require(isForSale(assetId) == false, "Already for sale");

        _market[assetId] = Offer(_msgSender(), _price);

        emit offered(_msgSender(), assetId, _price);
    }

    /**
     * @dev Returns whether the specified token is for sale
     */
    function isForSale(uint256 assetId) public view returns (bool) {
        return _market[assetId].owner != address(0) || ownerOf(assetId) == address(0);
    }

    /**
     * @dev Returns the price of the specified token
     */
    function priceOf(uint256 assetId) public view returns (uint256) {
        return _market[assetId].price;
    }

    /**
     *  Cancel asset offer
     */
    function cancel(uint256 assetId) public payable takeFee {
        require(ownerOf(assetId) == _msgSender(), "You don't own this asset");
        require(isForSale(assetId), "Asset not for sale");

        _market[assetId] = Offer(address(0), 0);

        emit canceled(_msgSender(), assetId);
    }

    /**
        * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual returns (uint256) {
        require(index < balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedAssets[owner][index];
    }

    /**
     * @dev Adding a asset to the list of owned assets
     */
    function addToOwnedAssets(address to, uint256 assetId) internal virtual {
        // Map tokenId to owner
        uint256 length = balanceOf(to);
        _ownedAssets[to][length] = assetId;
        _ownedAssetsIndex[assetId] = length;
    }

    /**
     * @dev Removing a asset from the list of owned assets
     */
    function removeFromOwnedTokens(address from, uint256 assetId) internal virtual {
        uint256 lastAssetIndex = balanceOf(from) - 1;
        uint256 assetIndex = _ownedAssetsIndex[assetId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (assetIndex != lastAssetIndex) {
            uint256 lastAssetId = _ownedAssets[from][lastAssetIndex];

            _ownedAssets[from][assetIndex] = lastAssetId; // Move the last token to the slot of the to-delete token
            _ownedAssetsIndex[lastAssetId] = assetIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedAssetsIndex[assetId];
        delete _ownedAssets[from][lastAssetIndex];
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() external view returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() external view returns (string memory) {
        return _symbol;
    }

    /**
    * @dev Returns the Uniform Resource Identifier (URI) for `assetId` token.
     */
    function tokenURI(uint256 assetId) external view returns (string memory) {
        if (direct) {
            return string(abi.encodePacked(_tokenURI, "/", assetId));
        }
        return _tokenURI;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function supportsInterface(bytes4 interfaceId) external pure returns (bool){
        return interfaceId == type(IERC721).interfaceId || interfaceId == type(IERC721Metadata).interfaceId;
    }

    function approve(address to, uint256 assetId) external {}

    function getApproved(uint256 assetId) external view returns (address operator) {}

    function isApprovedForAll(address owner, address operator) external view returns (bool) {}

    function safeTransferFrom(address from, address to, uint256 assetId) external {}

    function safeTransferFrom(address from, address to, uint256 assetId, bytes calldata data) external {}

    function setApprovalForAll(address operator, bool approved) external {}

    function transferFrom(address from, address to, uint256 assetId) external {}

}
