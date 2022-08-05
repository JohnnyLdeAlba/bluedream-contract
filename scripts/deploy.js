const contractABI = require('../BlueDream.abi.json');

async function mint(contract, deployer, quantity) {

  let index;
  for (index = 0; index < quantity; index++) {

    await contract.connect(deployer).mint(
      deployer.address,
      "",
    );
  }
}

async function main() {

  const [deployer] = await ethers.getSigners();

  console.log("Deploying contract with the account:", deployer.address);
  const ContractFactory = await ethers.getContractFactory("BlueDream");

  const deploymentData = ContractFactory.interface.encodeDeploy([deployer.address]);
  const estimatedGas = await ethers.provider.estimateGas({data: deploymentData});

  console.log("Gas price: " + estimatedGas);
  const contract = await ContractFactory.deploy(deployer.address);
  console.log("Contract address:", contract.address);

  await mint(contract, deployer, 20);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
