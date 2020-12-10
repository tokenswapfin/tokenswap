const TokenOfferingPlatformERC20 = artifacts.require("TokenOfferingPlatformERC20");

module.exports = async function (deployer) {
  const name = "Token Offering Platform";
  const symbol = "TOP";
  const totalSupply = "10000000000000000000000000"
  await deployer.deploy(TokenOfferingPlatformERC20, name, symbol, totalSupply);
};
