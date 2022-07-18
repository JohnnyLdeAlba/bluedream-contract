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

      url: "http://10.0.2.2:7545",
      // url: "http://127.0.0.1:8545",
      accounts: [
	"0x41a09adf93c06749328b4f2b3035adbcf164285334ffade4988424f8ce6c9b1f"
      ] 
    }
  }
};
