const contractABI = require('../BlueDream.abi.json');

async function main() {

  const [ deployer, account1 ] = await ethers.getSigners();

  let contract = new ethers.Contract("0xDA0593875B3bcF10ca73304ca6486A0B6a44fbF4", contractABI, deployer);
/*
  contract.on("Logging", (_before, _after, _result) => {
    console.log(
      " before: " + ethers.utils.formatEther(_before) +
      " _after: " + ethers.utils.formatEther(_after) +
      " _result: " + ethers.utils.formatEther(_result)
    );
  });
*/
  contract.on("Approval", (owner, approved, tokenId) => {
    console.log(
      " before: " + ethers.utils.formatEther(owner) +
      " _after: " + ethers.utils.formatEther(approved) +
      " _result: " + ethers.utils.formatEther(tokenId)
    );
  });

/*
  let before = await deployer.getBalance();
  console.log("Account balance before: " + before);

  let message = await contract.name();
  console.log("Returned: " + message);
*/

/*
	let index = 0;
  for (index = 0; index < 1; index++) {

    await contract.connect(deployer).mint(
      ethers.utils.keccak256(ethers.utils.toUtf8Bytes("ECCO")),
      "Eve",
      {value: ethers.utils.parseEther("0." + (index + 1))}
    );
  }

  let tokenId = 1;


  message = await contract.getToken(tokenId);
  console.log("Returned: " + message);
*/

let tokenId = 2;


if (false) {

  await contract.connect(deployer).listToken(
    ethers.utils.keccak256(ethers.utils.toUtf8Bytes("ECCO")),
    tokenId,
    10,
    {value: ethers.utils.parseEther("2")}
  );

}


/*
  let address = await deployer.getAddress();
  message = await contract.ownerOf(tokenId);
  console.log("Returned: " + message);
*/
// double check for empty addresses.

/*
  await contract.connect(deployer).approve(
    account1.getAddress(),
    tokenId
  );

return;
*/
try {
await contract.connect(account1).transferFrom(
    deployer.getAddress(),
    account1.getAddress(),
    tokenId
  );
}
catch (error) {
  console.log(error);
}

/*
  await contract.connect(account1).buyToken(
    ethers.utils.keccak256(ethers.utils.toUtf8Bytes("ECCO")),
    tokenId,
    {value: ethers.utils.parseEther("2")}
  );
*/
  console.log("Here");

  address = await deployer.getAddress();
  message = await contract.ownerOf(tokenId);
  console.log("Returned: " + message);

  return;

  let after = await deployer.getBalance();
  console.log("Account balance after: " + after);
  console.log("Difference after:: " + (before-after));
  console.log("Difference after: " + ethers.utils.formatEther(before-after));
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
