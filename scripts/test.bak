const contractABI = require('../Lemuria.abi.json');

async function main() {

  const [ deployer, account1 ] = await ethers.getSigners();

  let contract = new ethers.Contract("0x83E3a34805549De71AcaC7Bc1D5c57587E8415a9", contractABI, deployer);

  // await contract.connect(deployer).changeTrancheSize(500);

  await contract.connect(deployer).mint("Gohanks", {value: ethers.utils.parseEther("0.01")});
  // let message = await contract.getLemurian(2);
  // console.log(message);

  message = await contract.getLemurian(1);
  console.log(message);

  message = await deployer.getBalance();
  console.log(message);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
