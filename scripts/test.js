const contractABI = require('../BlueDream.abi.json');

async function mint(contract, deployer, quantity) {

  let index;
  for (index = 0; index < quantity; index++) {

    await contract.connect(deployer).mint(
      ethers.utils.keccak256(ethers.utils.toUtf8Bytes("ECCO")),
      "Namekian",
      {value: ethers.utils.parseEther("0.1")}
    );
  }
}

async function main() {

  const [ deployer, account1 ] = await ethers.getSigners();

  const contract = new ethers.Contract("0xE74aF62886c92C0113Caf9B1E69C38Faa0a9D387", contractABI, deployer);

  contract.on("Logging", (_before, _after, _result) => {

    console.log(
      " before: " + ethers.utils.formatEther(_before) +
      " _after: " + ethers.utils.formatEther(_after) +
      " _result: " + ethers.utils.formatEther(_result)
    );
  });

  let before = await deployer.getBalance();
  console.log("Account balance before: " + before);

  let message = await contract.name();
  console.log("Returned: " + message);

  // await mint(contract, deployer, 1);

  let tokenId = 7;

  message = await contract.getToken(tokenId);
  console.log("Returned: " + message);

  if (false) {

    try {

      await contract.connect(deployer).listToken(
        ethers.utils.keccak256(ethers.utils.toUtf8Bytes("ECCO")),
        tokenId,
        1000,
        {value: ethers.utils.parseEther("2")}
      );
    }
    catch (error) { console.log(error); };

    return;
  }

  message = await contract.getToken(tokenId);
  console.log("Returned: " + message);

/*
  try {

    await contract.connect(deployer).safeTransferFrom(
      deployer.getAddress(),
      account1.getAddress(),
      tokenId
    );
  }
  catch (error) { console.log(error); }
*/

  try {

    await contract.connect(account1).buyToken(
      ethers.utils.keccak256(ethers.utils.toUtf8Bytes("ECCO")),
      tokenId,
      {value: ethers.utils.parseEther("0.6")}
    );
  }
  catch (error) { console.log(error); }

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
