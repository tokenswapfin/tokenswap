const TokenOfferingPlatformERC20 = artifacts.require("TokenOfferingPlatformERC20");
const BitAuction = artifacts.require("BitAuction");

contract("BitAuction", async accounts => {
  let creatorAccount = accounts[0];
  let joinAccount = accounts[1];

  it("test join pool", async () => {
    const daliyMiningQty = '2750000000000000000000';
    const autionFeeRate = 20;
    const stakingPercent = 0;
    const createAutionFee = 0;
    const miningPeriod = 24; // hours
    let enable = true;
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
    //模拟建立2个KNC的pool
    const fromTokenQty = web3.utils.toWei('2', 'ether');
    const onlyBat = false;
    const toToken = "0x0000000000000000000000000000000000000000";
    const swapRatio = "3000000000000"; // 1:300
    const durationSeconds = 30 * 24 * 60 * 60; //30 days 
    const url1 = web3.utils.asciiToHex('');
    const url2 = web3.utils.asciiToHex('');
    // create pool step 1  -- approval erc20 token to bitAuction contract
    const approveTx = await top.approve(batp.address, fromTokenQty);
    assert.isNotEmpty(approveTx.tx, "approve failed");
    // create pool step 2  -- create it!
    const createPoolTx = await batp.createPool(poolName, poolType, fromToken, fromTokenQty, onlyBat, toToken, swapRatio, durationSeconds, url1, url2);
    assert.isNotEmpty(createPoolTx.tx, "create pool failed");

    // join pool should fail
    const ethCountToJoin = web3.utils.toWei('0.001', 'ether');
    // close bit aution
    enable = false;
    await batp.updateSetting(daliyMiningQty, autionFeeRate, stakingPercent, createAutionFee, feeAddress, miningPeriod, enable);
    try {
      const result = await batp.join(0, ethCountToJoin, { from: joinAccount, value: ethCountToJoin });
    }
    catch (e) {
      assert.include(e.message, 'maintaining','transferFrom without approve should throw err.')
    }
  });
});