const contractABI = require('../BlueDream.abi.json');

async function main() {

  const [ deployer, account1 ] = await ethers.getSigners();

  let contract = new ethers.Contract("0x53d4b43B7d7Fb04BB713c8DeE49B3BA86eE5DE04", contractABI, deployer);

  contract.on("Log", (tokenId) => { console.log("tokenId: " + tokenId); });

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
