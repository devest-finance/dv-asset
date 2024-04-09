// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/Context.sol";
import "@devest/contracts/DvFactory.sol";
import {DvAsset} from "./DvAsset.sol";

contract DvAssetFactory is DvFactory {

    constructor() DvFactory() {}

    /**
     * @dev detach a token from this factory
     */
    function detach(address payable _tokenAddress) external payable onlyOwner {
        DvAsset token = DvAsset(_tokenAddress);
        token.detach();
    }

    function issue(address tradingTokenAddress, string memory name, string memory symbol, string memory tokenURI) public payable isActive returns (address) {
        // take royalty
        require(msg.value >= _issueFee, "Please provide enough fee");
        if (_issueFee > 0)
            payable(_feeRecipient).transfer(_issueFee);

        // issue token
        DvAsset ticket = new DvAsset(tradingTokenAddress, name, symbol, tokenURI, address(this), _msgSender());

        emit deployed(_msgSender(), address(ticket));
        return address(ticket);
    }

}
