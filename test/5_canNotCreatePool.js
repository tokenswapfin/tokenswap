const TokenOfferingPlatformERC20 = artifacts.require("TokenOfferingPlatformERC20");
const BitAuction = artifacts.require("BitAuction");
const feeAddress = "0x2Ba4cfFc842F108D80f4DB7FF9B684Ca7DA8f4BA";

contract("BitAuction", async accounts => {
  let account = accounts[0];
  it("can not create pool when main contract disabled", async () => {

    const daliyMiningQty = '2750000000000000000000';
    const autionFeeRate = 20;
    const stakingPercent = 0;
    const createAutionFee = 0;
    const miningPeriod = 24; // hours
    const enable = false;
    const feeAddress = "0xb8b90C4dAc17BDE59B458b3537FDae5b7918926E";
    const name = "Token Offering Platform";
    const symbol = "TOP";
    const totalSupply = "10000000000000000000000000"
    let top = await TokenOfferingPlatformERC20.new(name, symbol, totalSupply);
    let batp = await BitAuction.new(top.address, feeAddress);
    // open bit aution
    await batp.updateSetting(daliyMiningQty, autionFeeRate, stakingPercent, createAutionFee, feeAddress, miningPeriod, enable);

    const bitAuctionStatus = await batp.getStatus();
    assert.equal(bitAuctionStatus.daliyMiningQty, daliyMiningQty, "daliyMiningQty update failed");
    assert.equal(bitAuctionStatus.autionFeeRate, autionFeeRate, "autionFeeRate update failed");
    assert.equal(bitAuctionStatus.stakingPercent, stakingPercent, "stakingPercent update failed");
    assert.equal(bitAuctionStatus.createAutionFee, createAutionFee, "createAutionFee update failed");
    assert.equal(bitAuctionStatus.miningPeriod, miningPeriod * 3600, "miningPeriod update failed");
    assert.equal(bitAuctionStatus.enable, enable, "enable should be false");
    assert.equal(bitAuctionStatus.feeAddr, feeAddress, "feeAddress update failed");

    const poolName = web3.utils.asciiToHex('testPool');
    const poolType = 1;
    const fromToken = top.address;
    const fromTokenQty = '2000000000000000000';
    const onlyBat = false;
    const toToken = "0x0000000000000000000000000000000000000000";
    const swapRatio = "3000000000000";
    const durationSeconds = 30 * 24 * 60 * 60; //30 days 
    const url1 = web3.utils.asciiToHex('');
    const url2 = web3.utils.asciiToHex('');
    // create pool step 1  -- approval erc20 token to bitAuction contract
    const approveTx = await top.approve(batp.address, fromTokenQty);
    assert.isNotEmpty(approveTx.tx, "create pool failed");

    try {
      await batp.createPool(poolName, poolType, fromToken, fromTokenQty, onlyBat, toToken, swapRatio, durationSeconds, url1, url2)
    }
    catch (e) {
      assert.include(e.message, 'maintaining', 'transferFrom without approve should throw err.')
    }
  });
});