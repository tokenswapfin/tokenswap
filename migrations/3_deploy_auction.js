const TokenOfferingPlatformERC20 = artifacts.require("TokenOfferingPlatformERC20");
const feeAddress = "0x2Ba4cfFc842F108D80f4DB7FF9B684Ca7DA8f4BA";
const SafeMath = artifacts.require("SafeMath");
const BitAuction = artifacts.require("BitAuction");

module.exports = async function (deployer) {
  const topToken = await TokenOfferingPlatformERC20.deployed();
  await deployer.deploy(SafeMath);
  deployer.link(SafeMath, BitAuction);
  await deployer.deploy(BitAuction, topToken.address, feeAddress);
};
