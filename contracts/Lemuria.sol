pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/ERC721A.sol";

error NameTooLong();
error MaxSupplyReached();
error NotEnoughETH();

/// @title Lemuria NFTs
/// @author Mode7.Eth (https://twitter.com/mode7eth)

contract Lemuria is ERC721A, Ownable, ReentrancyGuard {

  uint256 private constant MAX_SUPPLY = 10000;
  uint256 private constant MINT_PRICE = 1000000000000000000 * 0.01;

  string private _baseTokenURI;

  struct Lemurian {

    string name;
    bytes32 dna;
  }

  mapping(uint256 => Lemurian) lemurian;

  constructor()
    ERC721A("Lemuria", "MU") {}

  function rand() private returns (bytes32) {
    return keccak256(abi.encodePacked(block.timestamp, msg.sender));
  }

  function mint(string calldata name)
    external payable {

    uint256 tokenId = _nextTokenId();

    if (msg.value < MINT_PRICE)
      revert NotEnoughETH();

    if (bytes(name).length >= 32)
      revert NameTooLong();

    if (totalSupply() >= MAX_SUPPLY)
      revert MaxSupplyReached();

    unchecked {

      _safeMint(msg.sender, 1);
      lemurian[tokenId] = Lemurian(name, rand());
    }
  }

  function getLemurian(uint256 id)
    view public returns (Lemurian memory) {
      return lemurian[id];
  }

  function withdrawVault() external onlyOwner nonReentrant {

    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }

  function vaultBalance()
    public view onlyOwner returns (uint256)  {

    return address(this).balance;
  }
}
