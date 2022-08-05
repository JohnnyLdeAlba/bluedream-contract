const contractABI = require('../BlueDream.abi.json');

async function main() {

  const [deployer, account1] = await ethers.getSigners();

  const contract = new ethers.Contract("0x2A5A3Ad7F20059a48c7d253D9f93b0e7460806c7", contractABI, deployer);

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

  await contract.connect(account1).withdrawVault();

  message = await contract.connect(deployer).getToken(1);
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
