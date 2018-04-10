let Owned = artifacts.require('contracts/Owned.sol');
let MulaToken = artifacts.require('contracts/MulaToken.sol');
let MUTStorage = artifacts.require('contracts/storage/MUTStorage.sol');
let TokenController = artifacts.require('contracts/TokenController.sol');

const assertFail = require("./helpers/assertFail");

contract('MulaToken', function(accounts) {
    
    let owned;
    let MulaStorage;
    let token;
    let controller;
    let staking;

    const tokenAmount = 30 * 10 ** 18;
    
    beforeEach(async () => {
            
        owned = await Owned.new({from: accounts[0]});
    
        MulaStorage = await MUTStorage.new(Owned.address, {from: accounts[0]});
    
        token = await MulaToken.new(owned.address, tokenAmount, "HYPERGROWTH COIN", "HYP", 18, {from: accounts[0]});
    
        controller = await TokenController.new(owned.address, {from: accounts[0]});        

        await MulaStorage.addContract(token.address, {from: accounts[0]});
        
        await controller.changeHYPToken(token.address, {from: accounts[0]});

        await token.initialize(MulaStorage.address, controller.address, {from: accounts[0]});
    
    });

    it("MulaToken deployed correctly", async function() {
        
        let symbol = await token.symbol.call();

        assert.equal(symbol, 'HYP', 'Symbol name is not HYP');
    
        assert.equal(await token.name(), "HYPERGROWTH COIN");

        assert.equal(await token.getDecimals(), 18);

        assert.equal(await token.getTotalSupply(), tokenAmount);

    });

    it("Can transfer tokens between people", async function() {

        await token.addToBalance(accounts[1], 100, {from: accounts[0]});

        await token.increaseCirculation(100, {from: accounts[0]});

        await token.transfer(accounts[2], 50, "Sent", {from: accounts[1], gas: 1000000});

        assert.equal(await token.balanceOf(accounts[2]), 50);

    });

});