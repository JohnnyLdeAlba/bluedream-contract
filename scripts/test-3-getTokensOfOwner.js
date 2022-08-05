const contractABI = require('../BlueDream.abi.json');

async function main() {

  const [deployer, account1] = await ethers.getSigners();

  const contract = new ethers.Contract("0x0D1195d85653977629dc4e89Ec696c0cD03F8879", contractABI, deployer);

  let before = await deployer.getBalance();
  console.log("Account balance before: " + before);

  let message = await contract.name();
  console.log("Returned: " + message);

  let tokenId = 23;

  message = await contract.connect(deployer).getTokensOfOwner(deployer.address, 18, 2);
  console.log("Returned: " + message);

  message = await contract.connect(deployer).getToken(20);
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
