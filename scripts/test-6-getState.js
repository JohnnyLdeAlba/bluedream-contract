const contractABI = require('../BlueDream.abi.json');

async function main() {

  const [deployer, account1] = await ethers.getSigners();

  const contract = new ethers.Contract("0xC94635CF2e22c7d5122B573A035D04754D4C1506", contractABI, deployer);

  let before = await deployer.getBalance();
  console.log("Account balance before: " + before);

  let message = await contract.name();
  console.log("Returned: " + message);

  // await contract.connect(deployer).collect({value: ethers.utils.parseEther("1.0")});

  message = await deployer.getBalance();
  console.log("Account balance before: " + message);

  message = await ethers.provider.getBalance(contract.address);
  console.log("Contract balance: " + message);

  let tokenId = 23;

  message = await contract.connect(deployer).setState(deployer.address, "marky", "mark", false);
  message = await contract.connect(deployer).getState();
  console.log("Returned: " + message);

  message = await ethers.provider.getBalance(contract.address);
  console.log("Contract balance: " + message);

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
