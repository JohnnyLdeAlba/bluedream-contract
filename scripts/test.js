const contractABI = require('../BlueDream.abi.json');

async function main() {

  const [ deployer, account1 ] = await ethers.getSigners();

  let contract = new ethers.Contract("0xab8aC5F2c109049a38CE9c8351F3AbA7b91925e3", contractABI, deployer);

  let message = await deployer.getBalance();
  console.log("Account balance before: " + message);

  message = await contract.name();
  console.log("Returned: " + message);

  await contract.connect(deployer).mint(
    ethers.utils.keccak256(ethers.utils.toUtf8Bytes("ECCO")),
    "Eve",
    {value: ethers.utils.parseEther("0.1")}
  );

  message = await contract.getToken(1);
  console.log("Returned: " + message);

  message = await contract.getAllTokens(0,0);
  console.log("Returned: " + message);

  message = await deployer.getBalance();
  console.log("Account balance after: " + message);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
