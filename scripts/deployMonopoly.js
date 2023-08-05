const hre = require('hardhat');

async function main() {
  const subscriptionId ="5582";
  // mumbai
  const vrfCoordinator = '0x7a1bac17ccc5b313516c5e16fb24f7659aa5ebed';
  const keyHash = '0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f';
  // update after deployment
  const prizes = '0x2D9B50f5d7AEaddE0f02d75FA088c12D617aAb0F';

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