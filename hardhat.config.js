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
	"0x5af043fcef7f1d419f573185a5f90af14764ddff9da2d4db1be38b505fffcebe",
        "0x5f8e7dcdf8f94195e6fa72e57dc0115e1d7f820d17db4577cd5a24e31806c122",
	"0x439da59279db1c53cac466d3a42a62c75ffe9b2db94db607d4c85077bb380c60"
      ] 
    }
  }
};
