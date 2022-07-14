const contractAbi = require('../Lemuria.abi.json');

async function main() {

  const [ deployer ] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);
  const ContractFactory = await ethers.getContractFactory("Lemuria");

  const contract = await ContractFactory.deploy();
  console.log("Contract address:", contract.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
