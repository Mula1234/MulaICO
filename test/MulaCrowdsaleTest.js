let MulaCrowdsale = artifacts.require('contracts/MulaCrowdsale.sol');
let MulaToken = artifacts.require('contracts/MulaToken.sol');
let MultisigWallet = artifacts.require('contracts/MultiSigWallet.sol');
let TokenController = artifacts.require('contracts/TokenController.sol');
let Owned = artifacts.require('contracts/Owned');
let CrowdsaleStorage = artifacts.require('contracts/storage/CrowdsaleStorage.sol');
let DateTime = artifacts.require('contracts/libraries/DateTime.sol');
let SafeMath = artifacts.require('contracts/libraries/SafeMath.sol');
let MUTStorage = artifacts.require('contracts/storage/MUTStorage.sol');

const assertFail = require("./helpers/assertFail");

const increaseTime = require('./helpers/increaseTime');

contract('MulaCrowdsale', function(accounts) {

    const startBlock = web3.eth.blockNumber + 100;
    const endBlock = startBlock + 300;
    const rate = new web3.BigNumber(4000);
    const cap = new web3.BigNumber(5300000000000000000000); //5300 ether hardcap

    const tokenAmount = 30 * 10 ** 18;

    let Controller;
    let wallet;
    let _storage;
    let crowdsale;
    let owned;
    let token;
    let dateTime;
    let safeMath;
    let MulaStorage;

    beforeEach(async () => {

        owned = await Owned.new({from: accounts[0]});

        safeMath = await SafeMath.new({from: accounts[0]});

        token = await MulaToken.new(owned.address, tokenAmount, "Mula COIN", "MUT", 18, {from: accounts[0]});

        dateTime = await DateTime.new({from: accounts[0], gas: 3000000});

        MulaStorage = await MUTStorage.new(owned.address, {from: accounts[0]});

        Controller = await TokenController.new(owned.address, {from: accounts[0]});
        wallet = await MultisigWallet.new([accounts[0], accounts[1], accounts[2]], 2, {from: accounts[0]});
        _storage = await CrowdsaleStorage.new(owned.address, {from: accounts[0]} );
        crowdsale = await MulaCrowdsale.new(owned.address, { from: accounts[0] }); 

        await _storage.addContract(crowdsale.address, {from: accounts[0]});

        await crowdsale.changeCrowdsaleStorage(_storage.address, {from: accounts[0]});

        await crowdsale.changeDateTimeAPI(dateTime.address, {from: accounts[0]});

        await MulaStorage.addContract(token.address, {from: accounts[0]});

        await token.initialize(MulaStorage.address, Controller.address, {from:accounts[0]});

        await Controller.initialize(token.address, crowdsale.address, {from: accounts[0]});

    });

    it("Deploys contract with correct hardcap", async function() {

        await crowdsale.initialize(1, 2, rate, wallet.address, cap, Controller.address, _storage.address, dateTime.address, {from: accounts[0]});
        const hardcap = await crowdsale.weiCap.call();
        assert.equal(hardcap.toString(), cap.toString(), "Deployed hardcap is not equal to hardcap");

    });

    it("Can add days to array", async function() {

        await crowdsale.initialize(0, 2, rate, wallet.address, cap, Controller.address, _storage.address, dateTime.address, {from: accounts[0]});

        var days = await crowdsale.addDaysToArray.call({from: accounts[0]});

        assert.equal(1, days);

    });

    //Change the parameters in checkIfBonusDay to reflect the day that you are in

    it("Can check today's bonus", async function() {

        await crowdsale.initialize(0, 72, rate, wallet.address, cap, Controller.address, _storage.address, dateTime.address, {from: accounts[0]});

        await crowdsale.addDaysToArray({from: accounts[0]});

        var block = web3.eth.blockNumber;

        var timeStamp = web3.eth.getBlock(block).timestamp;

        var day = await dateTime.getDay.call(timeStamp);

        var month = await dateTime.getMonth.call(timeStamp);

        var year = await dateTime.getYear.call(timeStamp);

        var firstBonus = await crowdsale.checkIfBonusDay.call(day, month, year, {from: accounts[0]});

        assert.equal(20, firstBonus);

    });

    it("Checks that nobody can buy before the crowdsale begins", async function() {
        await crowdsale.initialize(1, 2, rate, wallet.address, cap, Controller.address, _storage.address, dateTime.address, {from: accounts[0]});

        await crowdsale.addDaysToArray.call({from: accounts[0]});

        await assertFail(async () => (
            crowdsale.buyTokens({ value: 500000000000000000, from: accounts[1] })
        ));
    });

    it("Checks that only owner can pause campaign", async function() {
        await crowdsale.initialize(1, 2, rate, wallet.address, cap, Controller.address, _storage.address, dateTime.address, {from: accounts[0]});

        await assertFail(async () => (
            crowdsale.pauseContribution({ from: accounts[1] })
        ));

        await crowdsale.pauseContribution({ from: accounts[0] });

        assert.equal(await crowdsale.paused.call(), true);

    });

    it("Checks that nobody can buy if the crowdsale is paused", async function() {
        await crowdsale.initialize(1, 2, rate, wallet.address, cap, Controller.address, _storage.address, dateTime.address, {from: accounts[0], gas: 900000});

        await crowdsale.addDaysToArray.call({from: accounts[0]});

        await crowdsale.pauseContribution({from: accounts[0]});
        await assertFail(async () => (
            crowdsale.buyTokens({ value: 500000000000000000, from: accounts[1] })
        ));
    });

    //Change the parameters when you call crowdsale.checkIfBonusDay.call to reflect the current date from
    //your callendar

    it("Checks that we can get correct bonus for timestamp and normal date", async function() {

        await crowdsale.initialize(0, 2, rate, wallet.address, cap, Controller.address, _storage.address, dateTime.address, {from: accounts[0], gas: 900000});

        await crowdsale.addDaysToArray({from: accounts[0]});

        var timestamp = await crowdsale.getCurrentTimestamp.call();

        var bonusFromTimestamp = await crowdsale.checkIfBonusDay.call(await dateTime.getDay.call(timestamp), await dateTime.getMonth.call(timestamp), await dateTime.getYear.call(timestamp));

        var block = web3.eth.blockNumber;

        var timeStamp = web3.eth.getBlock(block).timestamp;

        var day = await dateTime.getDay.call(timeStamp);

        var month = await dateTime.getMonth.call(timeStamp);

        var year = await dateTime.getYear.call(timeStamp);

        var bonusFromDate = await crowdsale.checkIfBonusDay.call(day, month, year);

        console.log(bonusFromTimestamp + " " + bonusFromDate);

        assert.equal(bonusFromDate, 20);

    });

    //Change the changeBonusForDate and checkIfBonusDay parameters to reflect the current date from your calendar

    it("Checks that owner can change bonuses", async function() {
        await crowdsale.initialize(1, 2, rate, wallet.address, cap, Controller.address, _storage.address, dateTime.address, {from: accounts[0], gas: 900000});

        await crowdsale.addDaysToArray({from: accounts[0]});

        await crowdsale.changeBonusForDate(5,1,2018,10,{from: accounts[0]});

        assert.equal(await crowdsale.checkIfBonusDay.call(5, 1, 2018), 10);

    });

    it("Checks tokens per investment", async function() {
        await crowdsale.initialize(1, 2, rate, wallet.address, cap, Controller.address, _storage.address, dateTime.address, {from: accounts[0], gas: 900000});

        await crowdsale.addDaysToArray({from: accounts[0]});

        console.log(await crowdsale.tokensPerInvestment.call(500000000000000000));

    });

    it("Checks that anyone can buy tokens after crowdsale has started", async function() {

        await crowdsale.initialize(0, 2, rate, wallet.address, cap, Controller.address, _storage.address, dateTime.address, {from: accounts[0], gas: 900000});

        await crowdsale.changeMaximumGasLimit(500000000000000, {from: accounts[0]});

        await crowdsale.addDaysToArray({from: accounts[0]});

        await crowdsale.buyTokens({ from: accounts[2], value: 500000000000000000 });

        let boughtTokens = await _storage.getInvestorTokens(accounts[2], {from: accounts[2]});

        assert.equal(2400, boughtTokens);

    });

    it("Checks that we get correct number of tokens", async function() {

        await crowdsale.initialize(0, 2, rate, wallet.address, cap, Controller.address, _storage.address, dateTime.address, {from: accounts[0], gas: 900000});

        assert.equal(4800, await crowdsale.getBonusRate(20));

    });

    it("Checks that investors can get a refund", async function() {

        await crowdsale.initialize(0, 1, rate, wallet.address, cap, Controller.address, _storage.address, dateTime.address, {from: accounts[0], gas: 900000});

        await crowdsale.changeMaximumGasLimit(1000000000000000, {from: accounts[0]});

        await crowdsale.addDaysToArray.call({from: accounts[0]});

        await crowdsale.buyTokens({ value: 1000000000000000000, from: accounts[1] });

        await crowdsale.refundInvestment(1, {from: accounts[1]});

        assert.equal(await _storage.getInvestorTokens(accounts[1], {from: accounts[0]}), 0);

    });

    it("Checks that gas prices over the wei limit are rejected", async function() {
        await crowdsale.initialize(0, 2, rate, wallet.address, cap, Controller.address, _storage.address, dateTime.address, {from: accounts[0], gas: 900000});

        await crowdsale.addDaysToArray.call({from: accounts[0]});

        await crowdsale.resumeContribution({ from: accounts[0] }); //waste one block
        await assertFail(async () => (
            crowdsale.buyTokens({ value: 1000000000000000000, from: accounts[1], gas: 9000000000000000001})
        ));

    });

    it("Checks that investors can't claim tokens before the end", async function() {
        await crowdsale.initialize(0, 10, rate, wallet.address, cap, Controller.address, _storage.address, dateTime.address, {from: accounts[0], gas: 900000});

        await crowdsale.addDaysToArray.call({from: accounts[0]});

        await assertFail(async () => (
            await crowdsale.claimTokens({from: accounts[1]})
        ));

    });

    it("Checks that investors can't invest above weiCap", async function() {
        await crowdsale.initialize(0, 10, rate, wallet.address, 400000000000000000, Controller.address, _storage.address, dateTime.address, {from: accounts[0], gas: 900000});

        await crowdsale.buyTokens({ value: 400000000000000000, from: accounts[1] });

        await crowdsale.buyTokens({ value: 400000000000000000, from: accounts[1] });

        console.log(await web3.eth.getBalance(crowdsale.address));

    });

    it("Checks that wei is returned to investor", async function() {
        await crowdsale.initialize(0, 10, rate, wallet.address, 400000000000000000, Controller.address, _storage.address, dateTime.address, {from: accounts[0], gas: 900000});

        await crowdsale.buyTokens({ value: 500000000000000000, from: accounts[1] });

        console.log(await web3.eth.getBalance(crowdsale.address));

    });

    it("Checks that contributed ether is forwarded to wallet", async function() {

        var block = web3.eth.blockNumber;
        
        var timeStamp = web3.eth.getBlock(block).timestamp;

        await crowdsale.initialize(0, 0, 500000000000000000, wallet.address, cap, Controller.address, _storage.address, dateTime.address, {from: accounts[0], gas: 900000});

        await crowdsale.changeMaximumGasLimit(5000000000000000000000, {from: accounts[0]});

        await crowdsale.addDaysToArray({from: accounts[0]});

        await crowdsale.buyTokens({ value: web3.toWei(0.5, "ether"), from: accounts[1] });

        await increaseTime.increaseTimeTo(timeStamp + increaseTime.duration.days(1));

        await crowdsale.safeWithdrawal({ from: accounts[0] });
        
        let walletBalanceAfter = await web3.eth.getBalance(wallet.address);

        assert.equal(web3.toWei(0.5, "ether").toString(), walletBalanceAfter.toString(), "Balance contributed is not equal to wallet balance");

    });

    it("Checks that investors can get their tokens", async function() {

        var block = web3.eth.blockNumber;
        
        var timeStamp = web3.eth.getBlock(block).timestamp;

        await crowdsale.initialize(0, 1, 4000, wallet.address, 500000000000000000, Controller.address, _storage.address, dateTime.address, {from: accounts[0], gas: 900000});

        await crowdsale.changeMaximumGasLimit(50000000000000000000, {from: accounts[0]});

        await crowdsale.addDaysToArray({from: accounts[0]});

        await crowdsale.buyTokens({ from: accounts[1], value: 500000000000000000 });

        await increaseTime.increaseTimeTo(timeStamp + increaseTime.duration.days(1));

        await crowdsale.safeWithdrawal({ from: accounts[0] });

        await crowdsale.claimTokens({from: accounts[1]});

        const balance = await MulaStorage.getBalance.call(accounts[1], {from: accounts[1]});

        assert.equal("2400", balance.toString());

    });

    it("Checks that bonus is computed correctly", async function() {

        await crowdsale.initialize(0, 2, rate, wallet.address, cap, Controller.address, _storage.address, dateTime.address, {from: accounts[0], gas: 900000});

        assert.equal(await crowdsale.getBonusRate(20), 4800);

        assert.equal(await crowdsale.getBonusRate(19), 4760);

        assert.equal(await crowdsale.getBonusRate(18), 4720);

        assert.equal(await crowdsale.getBonusRate(17), 4680);

        assert.equal(await crowdsale.getBonusRate(0), 4000);

    });

    //Change the day and month in the function call each time you call; you need the current day
    //and month for this to actually work

    it("Checks that we can identify if a day is with bonuses", async function() {

        await crowdsale.initialize(0, 2, rate, wallet.address, cap, Controller.address, _storage.address, dateTime.address, {from: accounts[0], gas: 900000});

        assert.equal(await crowdsale.checkIfBonusDay(5, 1, 2018), 0);

    });

    it("Checks that escape hatch blocks all necessary functions", async function() {

        await assertFail(async () =>(
            crowdsale.escapeHatch({from: accounts[1]})
        ));

        await crowdsale.escapeHatch({from: accounts[0]});

        await assertFail(async () => (
            crowdsale.buyTokens({from: accounts[1]})
        ));

        await assertFail(async () => (
            crowdsale.initialize(0, 1, rate, wallet.address, cap, Controller.address, _storage.address, dateTime.address, {from: accounts[0], gas: 900000})
        ));

        await assertFail(async () => (
            crowdsale.changeCrowdsaleStorage('0x0', {from: accounts[0]})
        ));

        await assertFail(async () => (
            crowdsale.switchTokenController('0x0', {from: accounts[0]})
        ));

        await assertFail(async () => (
            crowdsale.switchWallet('0x0', {from: accounts[0]})
        ));

        await assertFail(async () => (
            crowdsale.limitPerInvestor(10**18, {from: accounts[0]})
        ));

        await assertFail(async () => (
            await crowdsale.changeBaseRate(5000, {from: accounts[0]})
        ));

        await assertFail(async () => (
            crowdsale.buyTokens(21, {from: accounts[0]})
        ));

    });

});
