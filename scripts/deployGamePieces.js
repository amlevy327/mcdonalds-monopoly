const hre = require('hardhat');
require("dotenv").config();

async function main() {
  const subscriptionId = "5582";
  // mumbai
  const vrfCoordinator = '0x7a1bac17ccc5b313516c5e16fb24f7659aa5ebed';
  const keyHash = '0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f';
  // TODO: update after deployment
  const prizes = '0x45b498E9AF757736f51C662B3feE0D6687670106';

  const GamePieces = await hre.ethers.getContractFactory(
    'GamePieces',
  );

  const gamePieces = await GamePieces.deploy(
    subscriptionId,
    vrfCoordinator,
    keyHash,
    prizes
  );

  await gamePieces.waitForDeployment();

  console.log(`gamePieces deployed to ${await gamePieces.getAddress()}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});