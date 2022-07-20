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
	"0x5dd79a964c310da0eca343036f276b08fdfb3ae9a3bec2710f461a98f9af19f9",
        "0x7dc781266bb032560c75f9d9a6665228ca088d4c39debf822bb0c0934715a661",
	"0x439da59279db1c53cac466d3a42a62c75ffe9b2db94db607d4c85077bb380c60"
      ] 
    }
  }
};
