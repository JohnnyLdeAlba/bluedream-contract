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
	"0x4303520d9ba73d1f57d3c71a2683030aa926c29446911cfc1fe30c6ca50faa09",
        "0x4ed4451e3de3101449df6f8ecec3624ff01a8e61800b573a5df689634164f18d"
      ] 
    }
  }
};
