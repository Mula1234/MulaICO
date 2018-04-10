let TokenController = artifacts.require('contracts/TokenController.sol');
let Owned = artifacts.require('contracts/Owned.sol');
let MulaToken = artifacts.require('contracts/MulaToken.sol');
let MulaCrowdsale = artifacts.require('contracts/MulaCrowdsale.sol');
let MUTStorage = artifacts.require('contracts/storage/MUTStorage.sol');

const assertFail = require("./helpers/assertFail");

contract('TokenController', function(accounts) {

    let owned;
    let storage;
    let token;
    let controller;

    const tokenAmount = 30 * 10 ** 18;

    beforeEach(async () => {

        owned = await Owned.new({from: accounts[0]});

        storage = await MUTStorage.new(owned.address, {from: accounts[0]});

        token = await MulaToken.new(owned.address, tokenAmount, "Mula COIN", "MUT", 18, {from: accounts[0]});

        controller = await TokenController.new(owned.address, {from: accounts[0]});

        await storage.addContract(token.address, {from: accounts[0]});

        await token.initialize(storage.address, controller.address, {from: accounts[0]});

        await controller.changeHYPToken(token.address, {from: accounts[0]});

    });


    it("Only owner can do certain actions", async function() {

        await assertFail(async () => (
            controller.changeHYPToken(accounts[2], {from: accounts[1]})
        ));

        await assertFail(async () => (
            controller.changeOwned(accounts[1], {from: accounts[1]})
        ));

        await assertFail(async () => (
            controller.changeCrowdsale(accounts[2], {from: accounts[1]})
        ));

    });

    it("Owner can allocate tokens", async function() {

        await controller.allocateTokens(accounts[1], 100, {from: accounts[0]});

        let circulation = await token.currentlyInCirculation.call();

        assert.equal(100, circulation);

        assert.equal(100, await token.balanceOf(accounts[1]));

    });

});
