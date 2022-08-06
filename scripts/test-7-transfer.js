const contractABI = require('../BlueDream.abi.json');

async function main() {

  const [deployer, account1] = await ethers.getSigners();

  const contract = new ethers.Contract("0xC94635CF2e22c7d5122B573A035D04754D4C1506", contractABI, deployer);

  let before = await deployer.getBalance();
  console.log("Account balance before: " + before);

  let message = await contract.name();
  console.log("Returned: " + message);

  message = await deployer.getBalance();
  console.log("Account balance before: " + message);

  let tokenId = 4;

  message = await contract.connect(deployer).getToken(tokenId);
  console.log("Returned: " + message);

  message = await contract.connect(deployer).getOwnersTotalTokens(account1.address);
  console.log("Returned: " + message);

  await contract.connect(deployer).approve(account1.address, tokenId);
  await contract.connect(deployer)["safeTransferFrom(address,address,uint256)"](deployer.address, account1.address, tokenId);
  console.log("Returned: Done.");

  message = await contract.connect(deployer).getToken(tokenId);
  console.log("Returned: " + message);

  message = await contract.connect(deployer).getOwnersTotalTokens(deployer.address);
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
