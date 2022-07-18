pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";

/// @title Lemuria NFTs
/// @author Mode7.Eth (https://twitter.com/mode7eth)

// set name
// set key for marketplace, mint

contract BlueDream is ERC721A, Ownable, ReentrancyGuard {

  using Strings for uint256;

  uint32 private constant MODE0_CONTRACT_UNPAUSED = 0x00;
  uint32 private constant MODE1_MINT_PAUSED = 1 << 1;
  uint32 private constant MODE2_NAMECHANGE_PAUSED = 1 << 2;
  uint32 private constant MODE3_MARKETPLACE_PAUSED = 1 << 3;
  uint32 private constant MODE3_ACHIEVMENTS_PAUSED = 1 << 4;
  uint32 private constant MODE5_TRANSFERS_PAUSED = 1 << 5;
  uint32 private constant MODE6_TREASURY_PAUSED = 1 << 6;
  uint32 private constant MODE7_CONTRACT_PAUSED = 0xff;

  uint256 private constant MAX_SUPPLY = 10000;
  uint256 private constant WEI_TO_ETH = 1000000000000000000;

  uint256 private mode;

  uint256 private mintPrice;
  uint256 private listingPrice;
  uint256 private nameChangePrice;
  uint256 private achievementsPrice;
  uint256 private royalty;

  struct t_token {

    bool initialized;
    uint256 id;
    string name;
    bytes32 dna;
    bytes32 attributes;
    bool listed;
    uint256 price;
    address owner;
    uint256 achievements;
  }

  t_token[] tokens;
  mapping(address => uint256[]) tokenOwners;

  modifier haltOnMode(uint32 _mode) {

    _checkMode(_mode);
    _;
  }

  constructor()
    ERC721A("Blue Dream", "MU") {
   
    mode = MODE0_CONTRACT_UNPAUSED;
    // MODE1_MINT_PAUSED | MODE3_ACHIEVMENTS_PAUSED | MODE6_TREASURY_PAUSED - Treasury and achievements should always be paused for security reasons.

    _setMintPrice(100);
    _setListingPrice(5);
    _setNameChangePrice(50);
    _setRoyalty(8);  
  }

  function _checkMode(uint256 _mode)
    private view {

    if ((mode & _mode) == _mode)
      revert(string(abi.encodePacked(
        "FUNCTION_DISABLED_BY_MODE_", Strings.toHexString(mode))));
  }

  // Token Querying functions.

  function _startTokenId()
  internal view virtual
  returns (uint256) {
    return 1; }		    

  function getToken(uint256 id)
    public view returns (t_token memory) {
      return tokens[id];
  }

  function getAllTokens(uint256 startIndex, uint256 total)
    public view
    returns(t_token[] memory) {

      if (startIndex < 0 || startIndex > tokens.length - 1)
        revert("START_INDEX_OUT_OF_RANGE");

      else if (total < 0 || total > tokens.length)
        revert("TOTAL_OUT_OF_RANGE");

      if (total == 0)
        total = tokens.length;

      t_token[] memory tokensList;

      for (uint256 index = 0; index < total; index++)
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
    uint256 tokenId = 0;

    for (uint256 index = 0; index < total; index++) {

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

      tokens[tokenId] = t_token(
        true,
	name,
	tokenId,
	_rand(),
	_rand(),
	false,
	0,
	msg.sender);

      tokenOwners[msg.sender].push(tokenId);
    }

    _refundPriceDifference(mintPrice);
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

  function _isSenderTokenOwner(tokenId)
    private {

     if (tokens[tokenId].initialized == false)
      revert("TOKEN_DOES_NOT_EXIST");

    address ownerAddress = ownerOf(tokenId);

    if (msg.sender != ownerAddress)
      revert("SENDER_NOT_TOKEN_OWNER");   
  }

  function _refundPriceDifference(uint price)
    private {

    uint256 priceDifference = msg.value - price;
    uint256 adjustedPrice = msg.value - priceDifference;

    if (priceDifference > 0)
      msg.sender.call{value: priceDifference}("");
  }

  function changeName(uint256 tokenId, string name)
    external nonReentrant

    haltOnMode(MODE2_NAMECHANGE_PAUSED)
    payable {

    _isSenderTokenOwner(tokenId);

    if (msg.value < changeNamePrice)
      revert("CHANGE_NAME_PAYMENT_TOO_LOW");

    if (bytes(name).length >= 32)
      revert("NAME_TOO_LONG");

    tokens[tokenId].name = name;
    _refundPriceDifference(changeNamePrice);
  }

  function setTokenAchievements(uint256 achievements)
    external
    nonReentrant

    haltOnMode(MODE4_ACHIEVEMENTS_PAUSED)
    payable {

    if (msg.value < achievementsPrice)
      revert("ACHIEVEMENTS_PAYMENT_TOO_LOW");
	
    _setTokenAchievements(achievements);
    _refundPriceDifference(ahievementsPrice);
  }

  function listToken(uint256 tokenId, uint256 price)
    external nonReentrant

    haltOnMode(MODE3_MARKETPLACE_PAUSED)
    payable {

    _isSenderTokenOwner(tokenId);

    if (msg.value < changeNamePrice)
      revert("LISTING_PAYMENT_TOO_LOW");

    _list(tokenId, price);
    _refundPriceDifference(listingPrice);
  }

  function delistToken(uint256 tokenId)
    external nonReentrant
    haltOnMode(MODE3_MARKETPLACE_PAUSED) {

     _isSenderTokenOwner(tokenId);
    _list(tokenId, 0);
  }

  function buyToken(uint256 tokenId)
    external nonReentrant
    
    haltOnMode(MODE3_MARKETPLACE_PAUSED)
    payable {

    _isSenderTokenOwner(tokenId);

    address ownerAddress = ownerOf(tokenId);
    safeTransferFrom(ownerAddress, msg.sender, tokenId);
    
    _swapTokenOwner(ownerAddress, msg.sender, tokenId); 

    uint256 priceDifference = msg.value - token.price;
    uint256 adjustedPrice = msg.value - priceDifference;

    uint256 royaltyCut = adjustedPrice * royalty / 100;
    uint256 finalPrice = adjustedPrice - royaltyCut;

    // Refund buyer if they overpaid.
    msg.sender.call{value: priceDifference}("");
    (bool success,) = payable(ownerAddress).call{value: finalPrice}("");
    require(success, "BUY_TRANSFER_FAILED");
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override

    haltOnMode(MODE5_TRANSFERS_PAUSED)
    onlyOwner {

    super.transferFrom(from, to, tokenId);
    _swapTokenOwner(from, to, tokenId); 

    // Unlist the token on transfer. This is to prevent users from exploting the built in marketplace
    // into stealing items sold on other marketplaces like OpenSea.

    _list(tokenId, 0);
  }

  // Administrative functions.

  function _ETHToWEIConvert(uint256 price)
    private {
      return (WEI_TO_ETH * price)/1000;
  }

  function _setRoyalty(uint256 percentage)
    private {

      if (percentage < 0 || percentage > 100)
        revert("ROYALTY_OUT_OF_RANGE");

      royalty = percentage;
  }

  function _setTokenAchievements(uint256 tokenId, uint256 achievements)
    private {
      tokens[tokenId].achievments = achievments;
  }

  function setMintPrice(uint256 price)
    external
    onlyOwner {
      mintPrice = _ETHToWEIConvert(price);
  }

  function setNameChangePrice(uint256 price)
    external
    onlyOwner {
      nameChangePrice = _ETHToWEIConvert(price);
  }

  function setListingPrice(uint256 price)
    external
    onlyOwner {
      listingPrice = _ETHToWEIConvert(price);
  }

  function setAchievementsPrice(uint256 price)
    external
    onlyOwner {
      achievementsPrice = _ETHToWEIConvert(price);
  }

  function setRoyalty(uint256 percentage)
    external
    onlyOwner {
      _setRoyalty(percentage);
  }

  function setAccessKey(uint256 access, bytes32 key)
    external {

      if (access != MINT_ACCESS ||
       	  access != MARKETPLACE_ACCESS ||
 	  access != ACHIEVEMENTS_ACCESS)
            revert("INVALID_ACCESS_PARAMETER");

      accessKey[access] = key;
  }

  function withdrawVault()
    external nonReentrant

    haltOnMode(MODE6_TREASURY_PAUSED)
    onlyOwner {

    (bool success,) = msg.sender.call{value: address(this).balance}("");
    require(success, "TREASURY_TRANSFER_FAILED");
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
