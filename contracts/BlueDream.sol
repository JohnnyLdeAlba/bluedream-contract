pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721A.sol";

/// @title Blue Dream NFTs
/// @author Arkonviox (https://twitter.com/0xArkonviox)

contract BlueDream is ERC721A, Ownable, Pausable, ReentrancyGuard {

  event mintOK();
  event nameChangeOK();

  uint256 private constant maxSupply = 20;

  address controller;
  string private _contractURI;
  string private _tokenURI;

  struct t_state {

    address controller;
    string contractURI;
    string tokenURI;
    bool mintPaused;
  }

  struct t_token {

    uint256 tokenId;
    string name;
    bytes32 dna;
    bytes32 attributes;
    address owner;
  }

  uint256 randomIndex = 0;
  mapping(uint256 => t_token) tokens;
  mapping(address => uint256[]) tokensOfOwner;
  mapping(address => uint256) ownersTotalTokens;

  modifier controllerOnly() {

    if (_msgSenderERC721A() != controller)
      revert("SENDER_NOT_THE_CONTROLLER_ADDRESS");
    _;
  }

  constructor(address _controller)
    ERC721A("Blue Dream", "MU") {
    
      controller = _controller;
      _contractURI = "";
      _tokenURI = "";
      randomIndex = 1;
  }

  function _rand()
    private
    returns (bytes32) {

      if (randomIndex > 65536) {
        randomIndex = 1;
      }
      else randomIndex++;

      return keccak256(
        abi.encodePacked(
          randomIndex * 2,
          block.timestamp,
	  block.number + randomIndex * 3,
          block.timestamp ^ block.number + randomIndex * 5 % 128,
          block.timestamp | block.number + randomIndex * 7 % 256,
          msg.sender
        )
      );
  }

  function _isSenderTokenOwner(uint256 tokenId)
    private view {

    if (tokens[tokenId].tokenId == 0)
      revert("TOKEN_DOES_NOT_EXIST");

    address ownerAddress = ownerOf(tokenId);

    if (_msgSenderERC721A() != ownerAddress)
      revert("SENDER_NOT_TOKEN_OWNER");   
  }

  function _swapTokenOwner(address from, address to, uint tokenId)
    private {

    tokens[tokenId].owner = to;

    uint256 tokenIndex = 0;
    if (from != address(0)) {

      for (uint256 index = 0; index < tokensOfOwner[from].length; index++) {
    
        if (tokensOfOwner[from][index] == tokenId) {

          tokensOfOwner[from][tokenIndex] = tokensOfOwner[from][tokensOfOwner[from].length - 1];
          tokensOfOwner[from].pop();
	  ownersTotalTokens[from]--;
        }
      }
    }

    ownersTotalTokens[to]++;
    tokensOfOwner[to].push(tokenId);
  }

  function mint(address owner, string memory name)
    public
    controllerOnly
    whenNotPaused
    nonReentrant
    payable {

    if (totalSupply() >= maxSupply)
      revert("MINTED_OUT");

    uint256 tokenId = _nextTokenId();
    _safeMint(owner, 1);

    tokens[tokenId] = t_token(
      tokenId,
      name,
      _rand(),
      _rand(),
      owner
    );
    
    emit mintOK();
  }

  function changeName(
    uint256 tokenId,
    string memory name)

    public
    controllerOnly
    payable {

    _isSenderTokenOwner(tokenId);

    if (bytes(name).length >= 32)
      revert("NAME_TOO_LONG");

    tokens[tokenId].name = name;
    emit nameChangeOK();
  }

  function getToken(uint256 tokenId)
    public view
    returns (t_token memory) {

    uint256 totalTokens = totalSupply();

    if (tokenId == 0 || tokenId > totalTokens)
      tokenId = 1;

    return tokens[tokenId];
  }

  function getOwnersTotalTokens(address owner)
    public view
    returns (uint256) {
      return ownersTotalTokens[owner];
  }

  function getAllTokens(uint256 startIndex, uint256 total)
    public view
    returns (t_token[] memory) {

      uint256 totalTokens = totalSupply();

      if (startIndex == 0 || startIndex > totalTokens)
        startIndex = 1;

      if (total == 0 || total > totalTokens + 1 - startIndex)
        total = totalTokens + 1 - startIndex;

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

    uint256[] storage ownersTokens = tokensOfOwner[owner];

    if (startIndex >= ownersTokens.length)
      startIndex = 0;

    if (total == 0 || total > ownersTokens.length - startIndex)
      total = ownersTokens.length - startIndex;

    t_token[] memory tokensList = new t_token[](total);

    if (ownersTokens.length == 0)
      return tokensList;

    uint256 tokenId = 0;    
    uint256 index = 0;
    for (index = 0; index < total; index++) {

      tokenId = ownersTokens[startIndex + index];
      tokensList[index] = tokens[tokenId];
    }

    return tokensList;
  }

  function withdrawVault()
    external
    nonReentrant
    onlyOwner {

    (bool success,) = msg.sender.call{value: address(this).balance}("");
    require(success, "TREASURY_TRANSFER_FAILED");
  }

  function getState()
    public view
    onlyOwner
    returns (t_state memory) {
      return t_state(controller, _contractURI, _tokenURI, paused());
  }

  function setState(
    address __controller,
    string calldata __contractURI,
    string calldata __tokenURI,
    bool pauseMint)
    external
    onlyOwner {

      controller = __controller;
      _contractURI = __contractURI;
      _tokenURI = __tokenURI;
      
      if (pauseMint) {
        _pause();
      }
      else {
        _unpause();
      }
  }

  function _startTokenId()
   internal view virtual override
   returns (uint256) { return 1; }		    

  function _baseURI()
    internal view virtual override
    returns (string memory) {
      return _tokenURI;
  }

  function _afterTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) internal virtual override {
      _swapTokenOwner(from, to, startTokenId); 
  }
}
