const TokenOfferingPlatformERC20 = artifacts.require("TokenOfferingPlatformERC20");
const BitAuction = artifacts.require("BitAuction");

contract("BitAuction", async accounts => {
  let account = accounts[0];
  it("test create pool", async () => {

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
    // open bit aution
    await batp.updateSetting(daliyMiningQty, autionFeeRate, stakingPercent, createAutionFee, feeAddress, miningPeriod, enable);


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
    // create pool step 2  -- create it!
    const createPoolTx = await batp.createPool(poolName, poolType, fromToken, fromTokenQty, onlyBat, toToken, swapRatio, durationSeconds, url1, url2);
    assert.isNotEmpty(createPoolTx.tx, "create pool failed");

    const poolInfo = await batp.getPoolInfo(0);
    assert.equal(String(poolInfo[0]).indexOf(String(poolName)) > -1, true, "poolName is wrong");
    assert.equal(poolInfo[1], poolType, "poolType is wrong");
    assert.equal(poolInfo[2], account, "creator is wrong");
    assert.equal(poolInfo[3], fromToken, "fromToken is wrong");
    assert.equal(poolInfo[4], fromTokenQty, "fromTokenQty is wrong");
    assert.equal(poolInfo[5], onlyBat, "onlyBat is wrong");
    assert.equal(poolInfo[6], toToken, "toToken is wrong");
    assert.equal(poolInfo[7], swapRatio, "swapRatio is wrong");
    assert.equal(poolInfo[8] > 0, true, "createAt should generate than 0");
    assert.equal(poolInfo[9], durationSeconds, "durationSeconds is wrong");
    assert.equal(String(poolInfo[10]).indexOf(String(url1)) > -1, true, "url1 is wrong");
    assert.equal(String(poolInfo[11]).indexOf(String(url2)) > -1, true, "url2 is wrong");
  });
});