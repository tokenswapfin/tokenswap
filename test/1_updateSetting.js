const TokenOfferingPlatformERC20 = artifacts.require("TokenOfferingPlatformERC20");
const BitAuction = artifacts.require("BitAuction");

contract("BitAuction", async accounts => {
  it("test update setting", async () => {
    const daliyMiningQty = '2750000000000000000000';
    const autionFeeRate = 20;
    const stakingPercent = 0;
    const createAutionFee = 0;
    const miningPeriod = 24; // hours
    const enable = true;
    const feeAddress = "0xb8b90C4dAc17BDE59B458b3537FDae5b7918926E";
    const name = "Token Offering Platform";
    const symbol = "TOP";
    const totalSupply = "10000000000000000000000000"
    let top = await TokenOfferingPlatformERC20.new(name, symbol, totalSupply);
    let batp = await BitAuction.new(top.address, feeAddress);
    const updateResult = await batp.updateSetting(daliyMiningQty, autionFeeRate, stakingPercent, createAutionFee, feeAddress, miningPeriod, enable);
    assert.isNotEmpty(updateResult.tx, "Update BitAuction failed");
    const bitAuctionStatus = await batp.getStatus();
    assert.equal(bitAuctionStatus.daliyMiningQty, daliyMiningQty, "daliyMiningQty update failed");
    assert.equal(bitAuctionStatus.autionFeeRate, autionFeeRate, "autionFeeRate update failed");
    assert.equal(bitAuctionStatus.stakingPercent, stakingPercent, "stakingPercent update failed");
    assert.equal(bitAuctionStatus.createAutionFee, createAutionFee, "createAutionFee update failed");
    assert.equal(bitAuctionStatus.miningPeriod, miningPeriod * 3600, "miningPeriod update failed");
    assert.equal(bitAuctionStatus.enable, enable, "enable update failed");
    assert.equal(bitAuctionStatus.feeAddr, feeAddress, "feeAddress update failed");
  });
});