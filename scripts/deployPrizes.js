const hre = require('hardhat');

async function main() {

  const Prizes = await hre.ethers.getContractFactory(
    'Prizes',
  );

  const prizes = await Prizes.deploy(
  );

  await prizes.waitForDeployment();

  console.log(`prizes deployed to ${await prizes.getAddress()}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});