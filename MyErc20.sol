// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DecentralizedMarketplace is Ownable {
    using SafeERC20 for IERC20;

    IERC20 public paymentToken;

    uint256 public listingFee;
    uint256 public itemIdCounter;

    mapping(uint256 => Item) public items;
    mapping(address => uint256[]) public userItems;

    struct Item {
        uint256 id;
        address seller;
        string name;
        uint256 price;
        bool available;
    }

    event ItemListed(uint256 indexed itemId, address indexed seller, string name, uint256 price);
    event ItemPurchased(uint256 indexed itemId, address indexed buyer);

    modifier onlyItemSeller(uint256 _itemId) {
        require(items[_itemId].seller == msg.sender, "You are not the seller of this item");
        _;
    }

    modifier itemAvailable(uint256 _itemId) {
        require(items[_itemId].available, "Item is not available");
        _;
    }

    constructor(address _paymentToken, uint256 _listingFee) {
        require(_paymentToken != address(0), "Invalid token address");
        require(_listingFee > 0, "Listing fee must be greater than 0");

        paymentToken = IERC20(_paymentToken);
        listingFee = _listingFee;
    }
function listNewItem(string memory _name, uint256 _price) external {
        require(_price > 0, "Item price must be greater than 0");

        // Transfer listing fee from the seller to the contract
        paymentToken.safeTransferFrom(msg.sender, address(this), listingFee);

        uint256 newItemId = ++itemIdCounter;
        items[newItemId] = Item(newItemId, msg.sender, _name, _price, true);
        userItems[msg.sender].push(newItemId);

        emit ItemListed(newItemId, msg.sender, _name, _price);
    }
function purchaseItem(uint256 _itemId) external itemAvailable(_itemId) {
        Item storage item = items[_itemId];

        // Transfer item price from the buyer to the seller
        paymentToken.safeTransferFrom(msg.sender, item.seller, item.price);

        // Mark the item as no longer available
        item.available = false;

        emit ItemPurchased(_itemId, msg.sender);
    }
}
