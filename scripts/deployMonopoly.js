const hre = require('hardhat');

async function main() {
  const subscriptionId ="5582";
  // mumbai
  const vrfCoordinator = '0x7a1bac17ccc5b313516c5e16fb24f7659aa5ebed';
  const keyHash = '0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f';
  // update after deployment
  const prizes = '0x5d3f79504f8c1B52281bd14bDf3FdDDe43C47fcb';

  const Monopoly = await hre.ethers.getContractFactory(
    'Monopoly',
  );

  const monopoly = await Monopoly.deploy(
    subscriptionId,
    vrfCoordinator,
    keyHash,
    prizes
  );

  await monopoly.waitForDeployment();

  console.log(`monopoly deployed to ${await monopoly.getAddress()}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});