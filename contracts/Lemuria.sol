pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/ERC721A.sol";

error Mode1MintPaused();
error Mode2MarketPlacePaused();
error Mode3TransfersPaused();
error Mode7ContractPaused();

error NameTooLong();
error MaxSupplyReached();
error NotEnoughETH();
error SenderNotTokenOwner();
error BuyPriceTooLow();

/// @title Lemuria NFTs
/// @author Mode7.Eth (https://twitter.com/mode7eth)

contract BlueDream is ERC721A, Ownable, ReentrancyGuard {

  uint256 private constant MODE0_CONTRACT_UNPAUSED = 0;
  uint256 private constant MODE1_MINT_PAUSED = 1;
  uint256 private constant MODE2_MARKETPLACE_PAUSED = 1 << 1;
  uint256 private constant MODE3_TRANSFERS_PAUSED = 1 << 2;
  uint256 private constant MODE7_CONTRACT_PAUSED = 0xffffffff;

  uint256 private constant MAX_SUPPLY = 10000;
  uint256 private constant MINT_PRICE = 1000000000000000000 * 0.01;

  uint256 private mintPrice;
  uint256 private listingPrice;
  uint256 private royalty;

  uint256 private mode;
  string private _baseTokenURI;

  struct Token {

    string name;
    bytes32 dna;
    bytes32 attributes;
    bool listed;
    uint256 price;
  }

  mapping(uint256 => Token) token;

  constructor()
    ERC721A("Blue Dream", "MU") {
    
    mintPrice = 1000000000000000000 * 0.01;
    listingPrice = 1000000000000000000 * 0.005;
    royalty = 8;  
  }

  // needs work.
  function rand() private view returns (bytes32) {

    return keccak256(
      abi.encodePacked(
        block.timestamp,
        block.number,
        msg.sender
      )
    );
  }

  function mint(string calldata name)
    external payable {

    if ((mode & MODE1_MINT_PAUSED) == MODE1_MINT_PAUSED)
      revert Mode1MintPaused();

    uint256 tokenId = _nextTokenId();

    if (msg.value < MINT_PRICE)
      revert NotEnoughETH();

    if (bytes(name).length >= 32)
      revert NameTooLong();

    if (totalSupply() >= MAX_SUPPLY)
      revert MaxSupplyReached();

    unchecked {

      _safeMint(msg.sender, 1);
      token[tokenId] = Token(name, rand(), false, 0);
    }
  }

  function getToken(uint256 id)
    view public returns (Token memory) {
      return token[id];
  }

  function _list(uint256 tokenId, uint price) private {

    Token storage _token = token[tokenId];

    _token.listed = false;
    _token.price = price;
  }

  function listToken(uint256 tokenId, uint256 price)
    public nonReentrant payable {

    if ((mode & MODE2_MARKETPLACE_PAUSED) == MODE2_MARKETPLACE_PAUSED)
      revert Mode2MarketPlacePaused();

    address ownerAddress = ownerOf(tokenId);

    if (msg.sender != ownerAddress)
      revert SenderNotTokenOwner();

    _list(tokenId, price);
  }

  function delistToken(uint256 tokenId)
    public nonReentrant payable {

    if ((mode & MODE2_MARKETPLACE_PAUSED) == MODE2_MARKETPLACE_PAUSED)
      revert Mode2MarketPlacePaused();

    address ownerAddress = ownerOf(tokenId);

    if (msg.sender != ownerAddress)
      revert SenderNotTokenOwner();

    _list(tokenId, 0);
  }

  function buyToken(uint256 tokenId)
    public nonReentrant payable {

    if ((mode & MODE2_MARKETPLACE_PAUSED) == MODE2_MARKETPLACE_PAUSED)
      revert Mode2MarketPlacePaused();

    Token storage _token = token[tokenId];

    if (msg.value < _token.price)
      revert BuyPriceTooLow();

    address ownerAddress = ownerOf(tokenId);
    safeTransferFrom(ownerAddress, msg.sender, tokenId);

    // Send to tokenowner!
    (bool success, ) = msg.sender.call{value: _token.price}("");
    require(success, "Transfer failed.");
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override {

    if ((mode & MODE3_TRANSFERS_PAUSED) == MODE3_TRANSFERS_PAUSED)
      revert Mode3TransfersPaused();

    super.transferFrom(from, to, tokenId);
    _list(tokenId, 0);
  }

  function withdrawVault() external onlyOwner nonReentrant {

    if (mode == MODE7_CONTRACT_PAUSED)
      revert Mode7ContractPaused();

    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }

  function vaultBalance()
    public view onlyOwner returns (uint256)  {

    return address(this).balance;
  }
}
