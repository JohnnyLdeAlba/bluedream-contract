pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC721A.sol";

/// @title Lemuria NFTs
/// @author Mode7.Eth (https://twitter.com/mode7eth)

// Intercept approval and setApprovalForAll to shutdown transfers.

contract BlueDream is ERC721A, Ownable, ReentrancyGuard {

  using Strings for uint256;

  uint256 private constant MODE0_CONTRACT_UNPAUSED = 0x00;
  uint256 private constant MODE1_MINT_PAUSED = 1 << 1;
  uint256 private constant MODE2_NAMECHANGE_PAUSED = 1 << 2;
  uint256 private constant MODE3_MARKETPLACE_PAUSED = 1 << 3;
  uint256 private constant MODE4_ACHIEVEMENTS_PAUSED = 1 << 4;
  uint256 private constant MODE5_TRANSFERS_PAUSED = 1 << 5;
  uint256 private constant MODE6_TREASURY_PAUSED = 1 << 6;
  uint256 private constant MODE7_CONTRACT_PAUSED = 0xff;

  uint256 private constant MINT_ACCESS = 0;
  uint256 private constant MARKETPLACE_ACCESS = 1;
  uint256 private constant ACHIEVEMENTS_ACCESS = 2;
  uint256 private constant ADMIN_ACCESS = 3;

  uint256 private constant MAX_SUPPLY = 10000;
  uint256 private constant WEI_TO_ETH = 1000000000000000000;

  uint256 private mode;

  uint256 private mintPrice;
  uint256 private listingPrice;
  uint256 private nameChangePrice;
  uint256 private achievementsPrice;
  uint256 private royalty;

  string private _contractURI;
  string private _tokenURI;

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

  mapping(uint256 => t_token) tokens;
  mapping(address => uint256[]) tokenOwners;

  mapping(uint256 => bytes32) accessKey;

  modifier haltOnMode(uint256 _mode) {

    _checkMode(_mode);
    _;
  }

  constructor()
    ERC721A("Blue Dream", "MU") {
   
    mode = MODE0_CONTRACT_UNPAUSED; // MODE1_MINT_PAUSED | MODE3_ACHIEVMENTS_PAUSED | MODE6_TREASURY_PAUSED
    // By default mint, achievements, and treasury should be paused for security reasons.

    accessKey[MINT_ACCESS] = keccak256("ECCO");
    accessKey[MARKETPLACE_ACCESS] = keccak256("ECCO");

    mintPrice = _miliETHToWEIConvert(80);
    listingPrice = _miliETHToWEIConvert(8);
    nameChangePrice = _miliETHToWEIConvert(40);
    royalty = 8;  
  }

  function _miliETHToWEIConvert(uint256 price)
    private pure returns (uint256) {
      return (WEI_TO_ETH * price)/1000;
  }

  /* Token Querying Functions */

  function getToken(uint256 tokenId)
    public view
    returns (t_token memory) {

    uint256 totalTokens = totalSupply();

    if (tokenId == 0 || tokenId > totalTokens)
      tokenId = 1;

    return tokens[tokenId];
  }

  function getAllTokens(uint256 startIndex, uint256 total)
    public view
    returns(t_token[] memory) {

      uint256 totalTokens = totalSupply();

      if (startIndex == 0 || startIndex > totalTokens)
        startIndex = 1;

      if (total == 0 || total > totalTokens - startIndex)
        total = totalTokens - startIndex;

      t_token[] memory tokensList = new t_token[](total);
      if (totalTokens == 0)
        return tokensList;
 
      for (uint256 index = 0; index < total; index++) {

	t_token storage token = tokens[startIndex + index];
        tokensList[index] = token;
      }

      return tokensList;
  }

  function getTokensOfOwner(address owner, uint startIndex, uint total)

    public view
    returns(t_token[] memory) {

    uint256[] memory ownersTokens = tokenOwners[owner];

    if (startIndex >= ownersTokens.length)
      startIndex = 0;

    if (total == 0 || total > ownersTokens.length - startIndex)
      total = ownersTokens.length - startIndex;

    t_token[] memory tokensList = new t_token[](total);

    if (ownersTokens.length == 0)
      return tokensList;

    uint256 tokenId = 0;    
    for (uint256 index = 0; index < total; index++) {

      tokenId = ownersTokens[startIndex + index];
      tokensList[index] = tokens[tokenId];
    }

    return tokensList;
  }

  /* Minting Functions */

  function _rand()
    private view
    returns (bytes32) {

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

  function mint(bytes32 providedKey, string calldata name)
    external
    haltOnMode(MODE1_MINT_PAUSED)
    payable {

     _validAccessKey(MINT_ACCESS, providedKey);

    uint256 tokenId = _nextTokenId();

    // Check what amount exactly is being taken.

    if (msg.value < mintPrice)
      revert("NOT_ENOUGH_ETH");

    // Test to see what the true maxmimum is.

    // Total supply needs to be adjusted if max is 4 five are made which is correct
    // but not the number were looking for.
    if (totalSupply() >= MAX_SUPPLY)
      revert("MINTED_OUT");

    _safeMint(msg.sender, 1);

    tokens[tokenId] = t_token(
      true,
      tokenId,
      name,
      _rand(),
      _rand(),
      false,
      0,
      msg.sender,
      0);
    
    tokenOwners[msg.sender].push(tokenId);
    _refundPriceDifference(mintPrice);
  }

  /* Marketplace Functions */

  function _list(uint256 tokenId, uint price, bool listed)
    private {

    t_token storage token = tokens[tokenId];

    token.listed = listed;
    token.price = _miliETHToWEIConvert(price);
  }

  function _isSenderTokenOwner(uint256 tokenId)
    private view {

    if (tokens[tokenId].initialized == false)
      revert("TOKEN_DOES_NOT_EXIST");

    address ownerAddress = ownerOf(tokenId);

    if (msg.sender != ownerAddress)
      revert("SENDER_NOT_TOKEN_OWNER");   
  }

  function _swapTokenOwner(address from, address to, uint tokenId)
    private {

    tokens[tokenId].owner = to;

    if (from != address(0)) {

      tokenOwners[from][tokenId] = tokenOwners[from][tokenOwners[from].length - 1];
      tokenOwners[from].pop();
    }

    tokenOwners[to].push(tokenId);
  }

  function _refundPriceDifference(uint price)
    private {

    uint256 priceDifference = msg.value - price;
    if (priceDifference > 0)
      msg.sender.call{value: priceDifference}("");
    // Should emit an event?

  }

  function changeName(
    bytes32 providedKey,
    uint256 tokenId,
    string memory name)

    external nonReentrant
    haltOnMode(MODE2_NAMECHANGE_PAUSED)
    payable {

    _validAccessKey(MARKETPLACE_ACCESS, providedKey);
    _isSenderTokenOwner(tokenId);

    if (msg.value < nameChangePrice)
      revert("CHANGE_NAME_PAYMENT_TOO_LOW");

    if (bytes(name).length >= 32)
      revert("NAME_TOO_LONG");

    tokens[tokenId].name = name;
    _refundPriceDifference(nameChangePrice);
  }

  function setTokenAchievements(
    bytes32 providedKey,
    uint256 tokenId,
    uint256 achievements)
    external
    nonReentrant
    haltOnMode(MODE4_ACHIEVEMENTS_PAUSED)
    payable {

      _validAccessKey(ACHIEVEMENTS_ACCESS, providedKey);

      if (msg.value < achievementsPrice)
        revert("ACHIEVEMENTS_PAYMENT_TOO_LOW");
	
      tokens[tokenId].achievements = achievements;
      _refundPriceDifference(achievementsPrice);
  }

  function listToken(bytes32 providedKey, uint256 tokenId, uint256 price)
    external nonReentrant

    haltOnMode(MODE3_MARKETPLACE_PAUSED)
    payable {

    _validAccessKey(MARKETPLACE_ACCESS, providedKey);
    _isSenderTokenOwner(tokenId);

    if (msg.value < listingPrice)
      revert("LISTING_PAYMENT_TOO_LOW");

    _list(tokenId, price, true);
    _refundPriceDifference(listingPrice);
  }

  // Needs security inserted!!!!!
  function delistToken(uint256 tokenId)
    external nonReentrant
    haltOnMode(MODE3_MARKETPLACE_PAUSED) {

    _validAccessKey(MARKETPLACE_ACCESS, providedKey);
    _isSenderTokenOwner(tokenId);

     _isSenderTokenOwner(tokenId);
    _list(tokenId, 999999, false);
  }

  event Logging(uint256 _before, uint256 _after, uint256 _result);

  function buyToken(bytes32 providedKey, uint256 tokenId)
    external nonReentrant
    
    haltOnMode(MODE3_MARKETPLACE_PAUSED)
    payable {

    _validAccessKey(MARKETPLACE_ACCESS, providedKey);

    if (tokens[tokenId].initialized == false)
      revert("TOKEN_DOES_NOT_EXIST");

    if (tokens[tokenId].listed == false)
      revert("TOKEN_NOT_FOR_SALE");

    if (msg.value < tokens[tokenId].price)
      revert("BUY_PAYMENT_TOO_LOW");

    // We need to get the token price before it is transfered.
    // After it is transfered the token will get delisted and the price will be reset.
    uint256 tokenPrice = tokens[tokenId].price;

    address ownerAddress = ownerOf(tokenId);

    _approve(msg.sender, tokenId);
    safeTransferFrom(ownerAddress, msg.sender, tokenId);

    uint256 priceDifference = msg.value - tokenPrice;
    uint256 adjustedPrice = msg.value - priceDifference;

    uint256 royaltyCut = adjustedPrice * royalty / 100;
    uint256 finalPrice = adjustedPrice - royaltyCut;

    emit Logging(priceDifference, royaltyCut, finalPrice);

    // Refund buyer if they overpaid.
    msg.sender.call{value: priceDifference}("");
    (bool success,) = payable(ownerAddress).call{value: finalPrice}("");
    require(success, "BUY_TRANSFER_FAILED");
  }

  /* Administrative Functions */

  function _setRoyalty(uint256 percentage)
    private {

      if (percentage < 0 || percentage > 100)
        revert("ROYALTY_OUT_OF_RANGE");

      royalty = percentage;
  }

  function _setTokenAchievements(uint256 tokenId, uint256 achievements)
    private {
      tokens[tokenId].achievements = achievements;
  }

  function setMintPrice(uint256 price)
    external
    onlyOwner {
      mintPrice = _miliETHToWEIConvert(price);
  }

  function setNameChangePrice(uint256 price)
    external
    onlyOwner {
      nameChangePrice = _miliETHToWEIConvert(price);
  }

  function setListingPrice(uint256 price)
    external
    onlyOwner {
      listingPrice = _miliETHToWEIConvert(price);
  }

  function setAchievementsPrice(uint256 price)
    external
    onlyOwner {
      achievementsPrice = _miliETHToWEIConvert(price);
  }

  function setRoyalty(uint256 percentage)
    external
    onlyOwner {
      _setRoyalty(percentage);
  }

  function _checkMode(uint256 _mode)
    private view {

    if ((mode & _mode) == _mode)
      revert(string(abi.encodePacked(
        "FUNCTION_DISABLED_BY_MODE_", Strings.toHexString(mode))));
  }

  function _validAccessKey(uint256 access, bytes32 providedKey)
    private view {

      if (accessKey[access] != providedKey)
        revert("ACCESSKEY_INVALID");
  }

  function contractURI()
    public view
    returns (string memory) {
      return _contractURI;
  }


  function setContractURI(string memory URI)
    external
    onlyOwner {
      _contractURI = URI;
  }

  function setTokenURI(string memory URI)
    external
    onlyOwner {
      _tokenURI = URI;
  }

  function setAccessKey(
    bytes32 providedKey,
    uint256 access,
    bytes32 key)
    external

    haltOnMode(MODE6_TREASURY_PAUSED)
    onlyOwner{

      _validAccessKey(ADMIN_ACCESS, providedKey);

      if (access != MINT_ACCESS ||
       	  access != MARKETPLACE_ACCESS ||
 	  access != ACHIEVEMENTS_ACCESS ||
	  access != ADMIN_ACCESS)
            revert("INVALID_ACCESS_PARAMETER");

      accessKey[access] = key;
  }


  function withdrawVault(bytes32 providedKey)
    external nonReentrant

    haltOnMode(MODE6_TREASURY_PAUSED)
    onlyOwner {

    _validAccessKey(ADMIN_ACCESS, providedKey);

    (bool success,) = msg.sender.call{value: address(this).balance}("");
    require(success, "TREASURY_TRANSFER_FAILED");
  }

  function vaultBalance()
    public view

    onlyOwner
    returns (uint256) {
      return address(this).balance;
  }

  function setContractMode(bytes32 providedKey, uint256 _mode)
    external 
    onlyOwner {

      _validAccessKey(ADMIN_ACCESS, providedKey);
      mode = _mode;
  }

  function getContractMode()
    public view 

    onlyOwner
    returns (uint256) {
      return mode;
  }

 function giveKeysTo(bytes32 providedKey, address newOwner)
   external
   onlyOwner {

   _validAccessKey(ADMIN_ACCESS, providedKey);

   require(newOwner != address(0), "Ownable: new owner is the zero address");
   _transferOwnership(newOwner);
 }

 function throwAwayTheKeys(bytes32 providedKey)
   public virtual
   onlyOwner {

    _validAccessKey(ADMIN_ACCESS, providedKey);
    _transferOwnership(address(0));
 }

 /* Function Overrides */

 function _startTokenId()
   internal view virtual override
   returns (uint256) {return 1;}		    

  function _baseURI()
    internal view virtual override
    returns (string memory) {
      return _tokenURI;
  }

  function setApprovalForAll(address operator, bool approved)
    public virtual override
    haltOnMode(MODE5_TRANSFERS_PAUSED) { 
      super.setApprovalForAll(operator, approved);
  }

  function _approve(address to, uint256 tokenId)
    internal virtual override
    haltOnMode(MODE5_TRANSFERS_PAUSED) {   
      super._approve(to, tokenId);  
  }

  function approve(address to, uint256 tokenId)
    public virtual override
    haltOnMode(MODE5_TRANSFERS_PAUSED) {   
      super.approve(to, tokenId);  
  }

  function _beforeTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) internal virtual override
    haltOnMode(MODE5_TRANSFERS_PAUSED) {}

  function _afterTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) internal virtual override {

       _swapTokenOwner(from, to, startTokenId); 
      _list(startTokenId, 999999, false); 
  }

  // These need to be implemented.
  function renounceOwnership()
    public virtual override
    onlyOwner {}

  function transferOwnership(address newOwner)
    public virtual override
    onlyOwner {}
}
