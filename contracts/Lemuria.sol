pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";

/// @title Lemuria NFTs
/// @author Mode7.Eth (https://twitter.com/mode7eth)

// set name
// set key for marketplace, mint
// get all tokens from owner.

contract BlueDream is ERC721A, Ownable, ReentrancyGuard {

  using Strings for uint256;

  uint256 private constant MODE0_CONTRACT_UNPAUSED = 0x00;
  uint256 private constant MODE1_MINT_PAUSED = 0x01;
  uint256 private constant MODE2_MARKETPLACE_PAUSED = 0x02;
  uint256 private constant MODE3_TRANSFERS_PAUSED = 0x04;
  uint256 private constant MODE4_TREASURY_PAUSED = 0x08;
  uint256 private constant MODE7_CONTRACT_PAUSED = 0xff;

  uint256 private constant MAX_SUPPLY = 10000;
  uint256 private constant WEI_TO_ETH = 1000000000000000000;

  uint256 private mode;

  uint256 private mintPrice;
  uint256 private listingPrice;
  uint256 private royalty;

  struct t_token {

    string name;
    bytes32 dna;
    bytes32 attributes;
    bool listed;
    uint256 price;
    address owner;
  }

  t_token[] tokens;
  mapping(address => uint256[]) tokenOwners;

  modifier haltOnMode(uint256 _mode) {

    _checkMode(_mode);
    _;
  }

  constructor()
    ERC721A("Blue Dream", "MU") {
    
    _setMintPrice(1);
    _setListingPrice(5);
    _setRoyalty(8);  
  }

  function _checkMode(uint256 _mode)
    private view {

    if ((mode & _mode) == _mode)
      revert(string(abi.encodePacked(
        "FUNCTION_DISABLED_BY_MODE_", Strings.toHexString(mode))));
  }

  // Token Querying functions.

  function getToken(uint256 id)
    public view returns (t_token memory) {
      return tokens[id];
  }

  function getAllTokens(uint256 startIndex, uint256 total)
    public view returns(t_token[] memory) {

      if (startIndex < 0 || startIndex > tokens.length - 1)
        revert("START_INDEX_OUT_OF_RANGE");

      else if (total < 0 || total > tokens.length)
        revert("TOTAL_OUT_OF_RANGE");

      if (total == 0)
        total = tokens.length;

      t_token[] memory tokensList;

      for (uint index = 0; index < total; index++)
        tokensList[index] = tokens[startIndex + index];

	return tokensList;
  }

  function getTokensOfOwner(address owner, uint startIndex, uint total)

    public view
    returns(t_token[] memory) {

    if (tokenOwners[owner].length == 0)
      revert("TOKEN_OWNER_DOESNT_EXIST");

    if (startIndex < 0 || startIndex > tokenOwners[owner].length - 1)
      revert("START_INDEX_OUT_OF_RANGE");
    else if (total < 0 || total > tokenOwners[owner].length)
      revert("TOTAL_OUT_OF_RANGE");

    if (total == 0)
      total = tokenOwners[owner].length;

    t_token[] memory tokensList;
    uint tokenId = 0;

    for (uint index = 0; index < total; index++) {

      tokenId = tokenOwners[owner][index];
      tokensList[index] = tokens[tokenId];
    }

    return tokensList;
  }

  // Minting functions

  function _rand() private returns (bytes32) {

    return keccak256(
      abi.encodePacked(
        block.timestamp,
	block.number,
        block.timestamp ^ block.number % 128,
        block.timestamp | block.number % 256,
        msg.sender
      )
    );
  }

  function mint(string calldata name)
    external
    haltOnMode(MODE1_MINT_PAUSED)
    payable {

    uint256 tokenId = _nextTokenId();

    if (msg.value < mintPrice)
      revert("NOT_ENOUGH_ETH");

    if (bytes(name).length >= 32)
      revert("NAME_TOO_LONG");

    if (totalSupply() >= MAX_SUPPLY)
      revert("MINTED_OUT");

    unchecked {

      _safeMint(msg.sender, 1);

      tokens[tokenId] = t_token(name, _rand(), _rand(), false, 0, msg.sender);
      tokenOwners[msg.sender].push(tokenId);
    }
  }

  // Marketplace functions.

  function _list(uint256 tokenId, uint price)
    private {

    t_token storage token = tokens[tokenId];

    token.listed = false;
    token.price = price;
  }

  function _swapTokenOwner(address from, address to, uint tokenId)
    private {

    tokens[tokenId].owner = to;

    tokenOwners[from][tokenId] = tokenOwners[from][tokenOwners[from].length - 1];
    tokenOwners[from].pop();

    tokenOwners[to].push(tokenId);
  }

  function listToken(uint256 tokenId, uint256 price)
    external nonReentrant

    haltOnMode(MODE2_MARKETPLACE_PAUSED)
    payable {

    address ownerAddress = ownerOf(tokenId);

    if (msg.sender != ownerAddress)
      revert("SENDER_NOT_TOKEN_OWNER"); 

    _list(tokenId, price);
  }

  function delistToken(uint256 tokenId)
    external nonReentrant

    haltOnMode(MODE2_MARKETPLACE_PAUSED)
    payable {

    address ownerAddress = ownerOf(tokenId);

    if (msg.sender != ownerAddress)
      revert("SENDER_NOT_TOKEN_OWNER");

    _list(tokenId, 0);
  }

  function buyToken(uint256 tokenId)
    external nonReentrant
    
    haltOnMode(MODE2_MARKETPLACE_PAUSED)
    payable {

    t_token storage token = tokens[tokenId];

    if (msg.value < token.price)
      revert("BUY_PRICE_TOO_LOW");

    address ownerAddress = ownerOf(tokenId);
    safeTransferFrom(ownerAddress, msg.sender, tokenId);
    
    _swapTokenOwner(ownerAddress, msg.sender, tokenId); 

    uint256 priceDifference = msg.value - token.price;
    uint256 adjustedPrice = msg.value - priceDifference;

    uint256 royaltyCut = adjustedPrice * royalty / 100;
    uint256 finalPrice = adjustedPrice - royaltyCut;

    // Refund buyer if they overpaid.
    msg.sender.call{value: priceDifference}("");
    (bool success,) = ownerAddress.call{value: finalPrice}("");
    require(success, "BUY_TRANSFER_FAILED");
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override

    haltOnMode(MODE3_TRANSFERS_PAUSED)
    onlyOwner {

    super.transferFrom(from, to, tokenId);

    _swapTokenOwner(from, to, tokenId); 

    // Unlist the token on transfer. This is to prevent users from exploting the built in marketplace
    // into stealing items sold on other marketplaces like OpenSea.

    _list(tokenId, 0);
  }

  // Administrative functions.

  function _setMintPrice(uint256 price)
    private {
    mintPrice = (WEI_TO_ETH * price)/1000;
  }

  function _setListingPrice(uint256 price)
    private {
    listingPrice = (WEI_TO_ETH * price)/1000;
  }

  function _setRoyalty(uint256 percentage)
    private {

    if (percentage < 0 || percentage > 100)
      revert("ROYALTY_OUT_OF_RANGE");

    royalty = percentage;
  }

  function setMintPrice(uint256 price)
    external
    onlyOwner {
    _setMintPrice(price);
  }

  function setListingPrice(uint256 price)
    external
    onlyOwner {
    _setListingPrice(price);
  }

  function setRoyalty(uint256 percentage)
    external
   onlyOwner {
    _setRoyalty(percentage);
  }

  function withdrawVault()
    external nonReentrant

    haltOnMode(MODE4_TREASURY_PAUSED)
    onlyOwner {

    (bool success,) = msg.sender.call{value: address(this).balance}("");
    require(success, "TRANSFER_FAILED");
  }

  function vaultBalance()
    public view

    onlyOwner
    returns (uint256) {

    return address(this).balance;
  }

  function setContractMode(uint256 _mode)
    external 
    onlyOwner {
    mode = _mode;
  }

  function getContractMode()
    public view 

    onlyOwner
    returns (uint256) {

    return mode;
  }
}
