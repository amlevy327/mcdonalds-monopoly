const hre = require('hardhat');

async function main() {
  const subscriptionId ="5582";
  // mumbai
  const vrfCoordinator = '0x7a1bac17ccc5b313516c5e16fb24f7659aa5ebed';
  const keyHash = '0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f';

  const Monopoly = await hre.ethers.getContractFactory(
    'Monopoly',
  );

  const monopoly = await Monopoly.deploy(
    subscriptionId,
    vrfCoordinator,
    keyHash,
  );

  await monopoly.waitForDeployment();

  console.log(`deployed to ${await monopoly.getAddress()}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});