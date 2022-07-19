const contractABI = require('../BlueDream.abi.json');

async function main() {

  const [ deployer, account1 ] = await ethers.getSigners();

  let contract = new ethers.Contract("0x8E49DD6B845D8e69aA19984895DD8b1FbD955776", contractABI, deployer);

  contract.on("Log", (startIndex, total) => { console.log("index: " + startIndex + " total :" + total); });

  let message = await deployer.getBalance();
  console.log("Account balance before: " + message);

  message = await contract.name();
  console.log("Returned: " + message);

  let index = 0;
  for (index = 0; index < 50; index++) {

    await contract.connect(deployer).mint(
      ethers.utils.keccak256(ethers.utils.toUtf8Bytes("ECCO")),
      "Eve",
      {value: ethers.utils.parseEther("0.1")}
    );
  }

/*
  message = await contract.getToken(1);
  console.log("Returned: " + message);
*/

  let address = await deployer.getAddress();
  message = await contract.getAllTokens(10,10);
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
