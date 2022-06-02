const { expect } = require("chai");
const {
  ethers: {
    getContractFactory,
    BigNumber,
    getNamedSigners
  }, ethers
} = require("hardhat");

describe("StakeToken", function () {
  let stake, stakeToken, accounts;
  let deployer, caller;
  beforeEach("idk", async function () {
    accounts = await ethers.getSigners();
    ([deployer, caller] = accounts);
    const StakeToken = await hre.ethers.getContractFactory("StakeToken");
    stakeToken = await StakeToken.deploy();
    await stakeToken.deployed();
    const Stake = await hre.ethers.getContractFactory("Stake");
    stake = await Stake.deploy(stakeToken.address);
    await stake.deployed();
  })

  it("Should stake correctly.", async function () {
    await stakeToken.connect(deployer).allowance(deployer.address, caller.address);
    await stakeToken.connect(deployer).approve(caller.address, ethers.utils.parseUnits("50"));
    await stake.connect(caller).stake(ethers.utils.parseUnits("50"), 2000);
    expect(await stake.stakeInfo[deployer.address]).to.deep.equal([block.number + 2000, 2000, ethers.utils.parseUnits("50")]);
  });

  

});
