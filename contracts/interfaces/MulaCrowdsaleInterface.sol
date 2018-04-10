pragma solidity ^0.4.17;

import "contracts/interfaces/BaseCrowdsaleInterface.sol";

/// @author Stefan Ionescu - <stefanionescu@protonmail.com>

contract MulaCrowdsaleInterface is BaseCrowdsaleInterface {

    event AddedDaysToArray(uint256 length);

    function changeBonusForDate(uint256 _day, uint256 _month, uint256 _year, uint256 newBonus) public;

    //Initialize a new crowdsale
    function initialize(uint256 hoursUntilStart, uint256 hoursUntilEnd, uint256 _rate, address _wallet, uint256 _cap, address _token, address _storageAddress, address dateTimeAddr) public;

    function tokensPerInvestment(uint256 _investment) public constant returns (uint256);

    function getCurrentTimestamp() public constant returns (uint256);

    //Ether limit per investor; need KYC for each investor to make sure we can limit them
    function limitPerInvestor(uint256 limit) public;

    //Change how many SPN we offer for investments of under $10K
    function changeBaseRate(uint256 baseRate) public;

    function addDaysToArray() public returns (uint256);

    //Change max gas price allowed for buyTokens
    function changeMaximumGasLimit(uint256 gasLimit) public;

    //How much can an investor invest in the crowdsale at this moment?
    function computeAllowedInvestment(uint256 investment, address investor) public constant returns (uint256);

    //Check if a day is in the crowdsale timeline
    function checkIfBonusDay(uint256 _day, uint256 _month, uint256 _year) public constant returns (uint256);

    //How much bonus does one investor get for the ether sent
    function getBonusRate(uint256 bonus) public constant returns (uint256);

    //Called by investors when they want to withdraw their investment; can be used before crowdsale ends
    function refundInvestment(uint256 weiAmount) public;

    //Change the address of the contract that has time utilities
    function changeDateTimeAPI(address dateAPI) public;

    function investorInterfaceData() public constant returns (uint256, uint256, uint256, uint256);

}