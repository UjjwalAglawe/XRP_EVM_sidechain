// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.0/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract NFT is ERC721URIStorage {
    address payable public immutable feeAccount;
    uint public constant feePercent = 2;
    uint public itemCount;
    uint public tokenCount;

    constructor() ERC721("DApp NFT", "DAPP") {
        feeAccount = payable(msg.sender);
    }

    struct Item {
        address ogOwner;
        uint itemId;
        uint tokenId;
        uint256 price;
        address payable seller;
        bool sold;
    }

    mapping(uint => Item) public items;

    event Offered(
        uint itemId,
        uint tokenId,
        uint256 price,
        address indexed seller
    );

    event Bought(
        uint itemId,
        uint tokenId,
        uint256 price,
        address indexed seller,
        address indexed buyer
    );

    function mint(string memory _tokenURI, uint _price) external returns (uint) {
        tokenCount++;
        itemCount++;
        _safeMint(msg.sender, tokenCount);
        _setTokenURI(tokenCount, _tokenURI);

        items[itemCount] = Item({
            ogOwner: msg.sender,
            itemId: itemCount,
            tokenId: tokenCount,
            price: _price,
            seller: payable(msg.sender),
            sold: false
        });

        emit Offered(itemCount, tokenCount, _price, msg.sender);

        return tokenCount;
    }

    function purchaseItem(uint _itemId) external payable {
        uint256 totalPrice = getTotalPrice(_itemId);
        Item storage item = items[_itemId];

        require(_itemId > 0 && _itemId <= itemCount, "Item doesn't exist");
        require(msg.value >= totalPrice, "Not enough ether to cover item price and market fee");
        require(!item.sold, "Item already sold");

        item.sold = true;

        item.seller.transfer(item.price);
        feeAccount.transfer(totalPrice - item.price);

        item.seller = payable(msg.sender);

        emit Bought(_itemId, item.tokenId, item.price, item.ogOwner, msg.sender);
    }

    function seeItem(uint _itemId) external payable {
        uint256 totalPrice = getTotalPrice(_itemId);
        Item storage item = items[_itemId];

        require(_itemId > 0 && _itemId <= itemCount, "Item doesn't exist");
        require(msg.value >= totalPrice, "Not enough ether to cover item price and market fee");
        require(!item.sold, "Item already sold");

        uint256 sellerAmount = msg.value * (100 - feePercent) / 100;
        uint256 feeAmount = msg.value - sellerAmount;
        
        item.seller.transfer(sellerAmount);
        feeAccount.transfer(feeAmount);
       
    }

    function getTotalPrice(uint _itemId) view public returns (uint256) {
        return (items[_itemId].price * (100 + feePercent)) / 100;
    }

    function getOwner(uint _itemId) view public returns (address) {
        return items[_itemId].ogOwner;
    }

    function getCurrOwner(uint _itemId) view public returns (address) {
        return items[_itemId].seller;
    }

    function seeNFT(uint _itemId) external view returns (string memory) {
        
        return tokenURI(_itemId);
    }
}
