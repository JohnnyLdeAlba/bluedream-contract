const contractABI = require('../BlueDream.abi.json');

async function main() {

  const [deployer, account1] = await ethers.getSigners();

  const contract = new ethers.Contract("0x2A5A3Ad7F20059a48c7d253D9f93b0e7460806c7", contractABI, deployer);

  let before = await deployer.getBalance();
  console.log("Account balance before: " + before);

  let message = await contract.name();
  console.log("Returned: " + message);

  let tokenId = 23;

  // await contract.connect(account1).mint(deployer.address, "Bruno");
  await contract.connect(account1).changeName(1, "Bruno");

  message = await contract.getToken(tokenId);
  console.log("Returned: " + message);

  let after = await deployer.getBalance();
  console.log("Account balance after: " + after);
  console.log("Difference after:: " + (before - after));
  console.log("Difference after: " + ethers.utils.formatEther((before - after) + ""));
  console.log("Difference after: " + ethers.utils.formatEther((after - before) + ""));
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
