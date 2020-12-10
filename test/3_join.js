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
    const enable = true;

    const feeAccount = web3.eth.accounts.create();
    const feeAddress = "0xb8b90C4dAc17BDE59B458b3537FDae5b7918926E";
    const name = "Token Offering Platform";
    const symbol = "TOP";
    const totalSupply = "10000000000000000000000000"
    let top = await TokenOfferingPlatformERC20.new(name, symbol, totalSupply);
    let batp = await BitAuction.new(top.address, feeAddress);
    // open bit aution
    await batp.updateSetting(daliyMiningQty, autionFeeRate, stakingPercent, createAutionFee, feeAccount.address, miningPeriod, enable);

    const poolName = web3.utils.asciiToHex('testPool');
    const poolType = 1;
    const fromToken = top.address;
    //create Test KNC pool ( 2 KNC)
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

    // join pool - first time
    // mock first time auction  0.001 ETH

    const ethCountToJoin = web3.utils.toWei('0.001', 'ether');

    const creatorBalanceBeforeJoin = await web3.eth.getBalance(creatorAccount);

    const joinTx = await batp.join(0, ethCountToJoin, { from: joinAccount, value: ethCountToJoin });
    const creatorBalanceAfterJoin = await web3.eth.getBalance(creatorAccount);

    assert.isNotEmpty(joinTx.tx, "join pool failed");
    let currentPoolExtInfo = await batp.getPoolExtInfo(0);
    let remainTokenQty = web3.utils.toBN(fromTokenQty) - web3.utils.toBN(currentPoolExtInfo[0]);
    assert.equal(web3.utils.toBN(currentPoolExtInfo[0]), web3.utils.toWei('0.3', 'ether'), "swaped token wrong");
    assert.equal(remainTokenQty, web3.utils.toWei('1.7', 'ether'), "remain token wrong");

    //check creator receive eth 
    const creatorBalanceDiff = web3.utils.toBN(creatorBalanceAfterJoin).sub(web3.utils.toBN(creatorBalanceBeforeJoin));
    assert.equal(creatorBalanceDiff, ethCountToJoin * (1 - autionFeeRate / 10000), "transfer eth to creator wrong");


    //check auction fee
    const feeAddrBalance = await web3.eth.getBalance(feeAccount.address);
    assert.equal(feeAddrBalance, ethCountToJoin * autionFeeRate / 10000, "transfer fee to fee account wrong");

    //join pool - second time
    //mock second time auction  0.001 ETH
    const joinTx2 = await batp.join(0, ethCountToJoin, { from: joinAccount, value: ethCountToJoin });
    currentPoolExtInfo = await batp.getPoolExtInfo(0);
    remainTokenQty = web3.utils.toBN(fromTokenQty) - web3.utils.toBN(currentPoolExtInfo[0]);
    assert.isNotEmpty(joinTx2.tx, "join pool failed");
    assert.isTrue(joinTx2.receipt.status, "join pool tx status not true,2nd");
    assert.equal(remainTokenQty, web3.utils.toWei('1.4', 'ether'), "remain token wrong");

    //join pool - third time
    //mock thirdk time auction  0.001 ETH
    const joinTx3 = await batp.join(0, ethCountToJoin, { from: joinAccount, value: ethCountToJoin });
    currentPoolExtInfo = await batp.getPoolExtInfo(0);
    remainTokenQty = web3.utils.toBN(fromTokenQty) - web3.utils.toBN(currentPoolExtInfo[0]);
    assert.isNotEmpty(joinTx3.tx, "join pool failed");
    assert.isTrue(joinTx3.receipt.status, "join pool tx status not true,3th");
    assert.equal(remainTokenQty, web3.utils.toWei('1.1', 'ether'), "remain token wrong");
  });
});