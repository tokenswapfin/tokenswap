const DegoToken = artifacts.require("DegoToken");
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
    let testToken = await DegoToken.new();
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
    const fromToken = testToken.address;
    //create a test pool(1920 DEGO)
    const fromTokenQty = "1920000000000000000000";
    const onlyBat = false;
    const toToken = "0x0000000000000000000000000000000000000000";
    const swapRatio = "3200000000000"; // 1:320
    const durationSeconds = 30 * 24 * 60 * 60; //30 days 
    const url1 = web3.utils.asciiToHex('');
    const url2 = web3.utils.asciiToHex('');
    // create pool step 1  -- approval erc20 token to bitAuction contract
    const approveTx = await testToken.approve(batp.address, fromTokenQty);
    assert.isNotEmpty(approveTx.tx, "approve failed");

    console.log("test token", testToken.address)

    // create pool step 2  -- create it!
    const createPoolTx = await batp.createPool(poolName, poolType, fromToken, fromTokenQty, onlyBat, toToken, swapRatio, durationSeconds, url1, url2);
    assert.isNotEmpty(createPoolTx.tx, "create pool failed");
    const balance = await testToken.balanceOf(batp.address);
    console.log(balance)
    // assert.notequal(balance, web3.utils.toBN(fromTokenQty), "transfer into pool number not enough");
    // // join pool - first time
    // mock first time auction  0.001 ETH
    // let ethCountToJoin = web3.utils.toWei('6', 'ether');
    // const joinTx = await batp.join(0, ethCountToJoin, { from: joinAccount, value: ethCountToJoin });
    // assert.isNotEmpty(joinTx.tx, "join pool failed");
    // let currentPoolExtInfo = await batp.getPoolExtInfo(0);
    // let remainTokenQty = web3.utils.toBN(fromTokenQty) - web3.utils.toBN(currentPoolExtInfo[0]);
    // assert.notequal(web3.utils.toBN(currentPoolExtInfo[0]), web3.utils.toBN('1920000000000000000000'), "swaped token wrong");
    // assert.notequal(remainTokenQty, 0, "remain token wrong");
  });
});