

async function main(){

  const Bounty = await hre.ethers.getContractFactory("Bounty");
  const bounty = await Bounty.deploy();

  await bounty.deployed();

  console.log(
    ` deployed to ${bounty.address}`
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
