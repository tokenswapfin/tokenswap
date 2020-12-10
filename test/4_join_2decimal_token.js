const TestSdc = artifacts.require("TestSdc");
const BitAuction = artifacts.require("BitAuction");
const TokenOfferingPlatformERC20 = artifacts.require("TokenOfferingPlatformERC20");

contract("BitAuction", async accounts => {
  let creatorAccount = accounts[0];
  let joinAccount = accounts[1];

  it("test join pool", async () => {
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
    let testToken = await TestSdc.new('SDC', 'SD Coin', '1000000000'); 
    // open bit aution
    await batp.updateSetting(daliyMiningQty, autionFeeRate, stakingPercent, createAutionFee, feeAddress, miningPeriod, enable);

    const poolName = web3.utils.asciiToHex('testPool');
    const poolType = 1;
    const fromToken = testToken.address;
    //create SDN test pool (100K SDC)
    const fromTokenQty = 10000000;
    const onlyBat = false;
    const toToken = "0x0000000000000000000000000000000000000000";
    const swapRatio = "10000000000000"; // 1:1000
    const durationSeconds = 30 * 24 * 60 * 60; //30 days 
    const url1 = web3.utils.asciiToHex('');
    const url2 = web3.utils.asciiToHex('');
    // create pool step 1  -- approval erc20 token to bitAuction contract
    const approveTx = await testToken.approve(batp.address, fromTokenQty);
    assert.isNotEmpty(approveTx.tx, "approve failed");
    // create pool step 2  -- create it!
    const createPoolTx = await batp.createPool(poolName, poolType, fromToken, fromTokenQty, onlyBat, toToken, swapRatio, durationSeconds, url1, url2);
    assert.isNotEmpty(createPoolTx.tx, "create pool failed");

    // join pool - first time
    //mock first time auction  0.001 ETH
    let ethCountToJoin = web3.utils.toWei('0.001', 'ether');
    const joinTx = await batp.join(0, ethCountToJoin, { from: joinAccount, value: ethCountToJoin });
    assert.isNotEmpty(joinTx.tx, "join pool failed");
    let currentPoolExtInfo = await batp.getPoolExtInfo(0);
    let remainTokenQty = web3.utils.toBN(fromTokenQty) - web3.utils.toBN(currentPoolExtInfo[0]);
    assert.equal(web3.utils.toBN(currentPoolExtInfo[0]), 100, "swaped token wrong");
    assert.equal(remainTokenQty, 9999900, "remain token wrong");
    //join pool - second time
    //mock second time auction  0.001 ETH
    const joinTx2 = await batp.join(0, ethCountToJoin, { from: joinAccount, value: ethCountToJoin });
    currentPoolExtInfo = await batp.getPoolExtInfo(0);
    remainTokenQty = web3.utils.toBN(fromTokenQty) - web3.utils.toBN(currentPoolExtInfo[0]);
    assert.isNotEmpty(joinTx2.tx, "join pool failed");
    assert.isTrue(joinTx2.receipt.status, "join pool tx status not true,2nd");
    assert.equal(web3.utils.toBN(currentPoolExtInfo[0]), 200, "swaped token wrong");
    assert.equal(remainTokenQty,9999800, "remain token wrong");

    //join pool - third time
    //mock third time auction  1 ETH
    ethCountToJoin = web3.utils.toWei('1', 'ether');
    const joinTx3 = await batp.join(0, ethCountToJoin, { from: joinAccount, value: ethCountToJoin });
    currentPoolExtInfo = await batp.getPoolExtInfo(0);
    remainTokenQty = web3.utils.toBN(fromTokenQty) - web3.utils.toBN(currentPoolExtInfo[0]);
    assert.isNotEmpty(joinTx3.tx, "join pool failed");
    assert.isTrue(joinTx3.receipt.status, "join pool tx status not true,3th");
    assert.equal(web3.utils.toBN(currentPoolExtInfo[0]), 100200, "swaped token wrong");
    assert.equal(remainTokenQty, 9899800, "remain token wrong");
  });
});