let MultisigWallet = artifacts.require('contracts/MultiSigWallet.sol');
let Owned = artifacts.require('contracts/Owned');

const assertFail = require("./helpers/assertFail");

contract('MultisigWallet', function(accounts) {

    let wallet;
    let owned;

    beforeEach(async () => {

        owned = await Owned.new({from: accounts[0]});

        wallet = await MultisigWallet.new([accounts[0], accounts[1], accounts[2]], 2, {from: accounts[0]});

    });

    it("Check if wallet is deployed", async function() {

        assert(wallet.address != null);

    });

    it("Send ether to wallet", async function() {

        web3.eth.sendTransaction({from: accounts[0], to: wallet.address, value: web3.toWei(1, "ether")});

        assert.equal(web3.toWei(1, "ether"), web3.eth.getBalance(wallet.address));

    });

});
