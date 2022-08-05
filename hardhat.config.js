/** @type import('hardhat/config').HardhatUserConfig */

require("@nomicfoundation/hardhat-toolbox");
require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-waffle");

module.exports = {
  solidity: "0.8.9",
  defaultNetwork: "hardhat",
  networks: {

    hardhat: {
      allowUnlimitedContractSize: true
    },

    testnet: {
      allowUnlimitedContractSize: true,

      // url: "http://10.0.2.2:7545",
      url: "http://127.0.0.1:8545",
      accounts: [
	"0x9491db8a7beb77b4be1cf5ebf816db30b1b701e54e51e04f424a4d67df5b0378",
        "0x4c4e916f50374dffed57f5d7cc0cf48d02d5c149542276ef49dc32b84107188e",
	"0x439da59279db1c53cac466d3a42a62c75ffe9b2db94db607d4c85077bb380c60"
      ] 
    }
  }
};
