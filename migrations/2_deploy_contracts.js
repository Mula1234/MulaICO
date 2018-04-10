var Owned = artifacts.require('contracts/Owned.sol');
var TokenController = artifacts.require('contracts/TokenController.sol');
var MultisigWallet = artifacts.require('contracts/MultiSigWallet.sol');
var MulaCrowdsale = artifacts.require('contracts/MulaCrowdsale.sol');
var MulaToken = artifacts.require('contracts/MulaToken.sol');
var CrowdsaleStorage = artifacts.require('contracts/storage/CrowdsaleStorage.sol');
var MUTStorage = artifacts.require('contracts/storage/MUTStorage.sol');
var DateTime = artifacts.require('contracts/libraries/DateTime.sol');

module.exports = async function(deployer, network, accounts) {

    const startBlock = web3.eth.blockNumber + 300;
    const endBlock = startBlock + 300;
    const rate = new web3.BigNumber(4000);
    const cap = new web3.BigNumber(5300000000000000000000); //5.3K ether hardcap

    const premintedTokens = 3 * 10 ** 9;

    await deployer.deploy(Owned, { from: accounts[0] });
    await deployer.deploy(DateTime, {from: accounts[0]});
    await deployer.deploy(MultisigWallet, [accounts[0], accounts[1], accounts[2]], 2, {from: accounts[0]});
    await deployer.deploy(MulaToken, Owned.address, premintedTokens, "MULA COIN", "MUT", 18, {from: accounts[0]});
    await deployer.deploy(TokenController, Owned.address, {from: accounts[0]});
    await deployer.deploy(MulaCrowdsale, Owned.address, {from: accounts[0]});
    await deployer.deploy(CrowdsaleStorage, Owned.address, {from: accounts[0]});
    await deployer.deploy(MUTStorage, Owned.address, {from: accounts[0]});

    await web3.eth.contract(MulaCrowdsale.abi).at(MulaCrowdsale.address)
            .changeDateTimeAPI(DateTime.address, {from: accounts[0]});

    //Set the crowdsale as current controller, allowing the crowdsale to allocate tokens
    await web3.eth.contract(TokenController.abi).at(TokenController.address)
        .changeCrowdsale(MulaCrowdsale.address, {from: accounts[0]});

    await web3.eth.contract(TokenController.abi).at(TokenController.address)
        .changeHYPToken(MulaCrowdsale.address, {from: accounts[0]});

    await web3.eth.contract(MulaToken.abi).at(MulaToken.address)
        .changeController(TokenController.address, {from: accounts[0]});

    await web3.eth.contract(MulaToken.abi).at(MulaToken.address)
        .changeMUTStorage(MUTStorage.address, {from: accounts[0]});

    //initialize crowdsale
    await web3.eth.contract(MulaCrowdsale.abi).at(MulaCrowdsale.address)
        .initialize(startBlock, endBlock, rate, MultisigWallet.address, cap, TokenController.address, CrowdsaleStorage.address, DateTime.address, {from: accounts[0], gas: 1900000 });

};