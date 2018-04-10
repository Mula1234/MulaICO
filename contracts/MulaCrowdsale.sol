pragma solidity ^0.4.17;

/// @author Stefan Ionescu - <stefanionescu@protonmail.com>

import "contracts/Owned.sol";
import "contracts/interfaces/TokenControllerInterface.sol";
import "contracts/interfaces/MulaCrowdsaleInterface.sol";
import "contracts/storage/CrowdsaleStorage.sol";
import "contracts/libraries/SafeMath.sol";
import "contracts/interfaces/DateTimeAPI.sol";

contract MulaCrowdsale is MulaCrowdsaleInterface {

    using SafeMath for uint256;

    //The storage for this crowdsale; we keep storage and logic separated in case we want to
    //upgrade this contract because of bugs, attacks etc
    CrowdsaleStorage internal _storage;

    //HYP token Controller
    TokenControllerInterface internal token;

    //Date time functions
    DateTimeAPI dateTime;

    //Contract which dictates who owns this campaign
    Owned private owned;

    //address where funds are collected
    address internal wallet;

    //for escape hatch; if 0, all functions can be used; if 1, only some functions can be used
    uint256 public blockAttack = 0;

    //maximum gas price for contribution transactions
    uint256 public MAX_GAS_PRICE = 9000000000000000000;

    //start and end times where investments are allowed (both inclusive)
    uint256 public startTime;
    uint256 public endTime;

    //how many token units a buyer gets per wei
    uint256 public rate;

    //amount of raised money in wei
    uint256 public weiRaised;

    //hard cap, campaign ends after reached
    uint256 public weiCap;

    //how much Ether an investor can actually invest in the crowdsale; if 0, any investor can send as much Ether as they want
    uint256 public investorLimit = 0;

    uint256 private oneEther = 10 ** 18;

    mapping(uint256 => uint256) internal activeDays;

    //allows for owner to pause the campaign if needed
    bool public paused;

    modifier afterDeadline() {

        require(now >= endTime || weiRaised >= weiCap);
         _;

    }

    //Used when we want to block the majority of functions from being called
    modifier hatch() {

        require(blockAttack == 0);
        _;

    }

    //Check if we paused campaign
    modifier notPaused() {
        require(!paused);
        _;
    }

    //Check that campaign didn't end in order to allow refunds
    modifier refundCondition() {

        require(now < endTime || weiRaised >= weiCap);
        _;

    }

    //verifies that gas price is below max gas price (prevents "cutting in line")
    modifier validGasPrice() {
        require(tx.gasprice <= MAX_GAS_PRICE);
        _;
    }

    ///@dev `owner` is the only address that can call a function with this
    ///modifier
    modifier onlyOwner() {
        require(msg.sender == owned.getOwner());
        _;
    }

    function MulaCrowdsale(address _owned) {
        paused = false;
        owned = Owned(_owned);
    }

    function changeOwned(address _owned) public onlyOwner {

        owned = Owned(_owned);

    }

    function changeDateTimeAPI(address dateAPI) public onlyOwner {

        dateTime = DateTimeAPI(dateAPI);

    }

    function initialize(uint256 hoursUntilStart, uint256 hoursUntilEnd, uint256 _rate, address _wallet, uint256 _cap, address _token, address _storageAddress, address dateTimeAddr) public onlyOwner hatch {

        require(hoursUntilStart >= 0);
        require(hoursUntilEnd >= 0);
        require(_rate > 0);
        require(_wallet != 0x0);
        require(_cap > 0);
        require(_token != 0x0);

        startTime = now + hoursUntilStart * 1 hours;
        endTime = startTime + hoursUntilEnd * 1 hours;
        rate = _rate;
        wallet = _wallet;
        weiCap = _cap;
        token = TokenControllerInterface(_token);
        _storage = CrowdsaleStorage(_storageAddress);

        dateTime = DateTimeAPI(dateTimeAddr);

    }

    function getSaleStart() constant returns (uint256, uint256, uint256) {

        return (dateTime.getYear(startTime), dateTime.getMonth(startTime), dateTime.getDay(startTime));

    }

    function addDaysToArray() public returns (uint256) {

        require(msg.sender == owned.getOwner());

        uint256 currentTime = startTime;
        uint256 length = 0;
        uint256 mappingKey = 0;

        do {

            mappingKey = dateTime.getYear(currentTime);

            uint256 month = dateTime.getMonth(currentTime);

            mappingKey = mappingKey.mul(100);
            
            mappingKey = mappingKey.add(month);

            uint256 day = dateTime.getDay(currentTime);

            mappingKey = mappingKey.mul(100);
            
            mappingKey = mappingKey.add(day);

            activeDays[mappingKey] = 20 - length;

            mappingKey = 0;

            length = length.add(1);

            currentTime = currentTime.add(24 hours);

        } while (currentTime <= endTime);

        return length;

    }

    function changeCrowdsaleStorage(address _storageAddress) public onlyOwner hatch {

        _storage = CrowdsaleStorage(_storageAddress);

    }

    // Pauses the contribution if there is any issue
    function pauseContribution() public onlyOwner {
        paused = true;
    }

    // Resumes the contribution
    function resumeContribution() public onlyOwner hatch {
        paused = false;
    }

    function switchTokenController(address _token) public onlyOwner hatch {

        token = TokenControllerInterface(_token);

    }

    function switchWallet(address _wallet) public onlyOwner hatch {

        wallet = _wallet;

    }

    // This will not give correct results; investors need to use the official function because
    // here we can't compute values properly
    function () payable {
        buyTokens();
    }

    function limitPerInvestor(uint256 limit) public onlyOwner hatch {

        investorLimit = limit;

    }

    function changeBaseRate(uint256 baseRate) public onlyOwner hatch {

        rate = baseRate;

    }

    function changeMaximumGasLimit(uint256 gasLimit) public onlyOwner hatch {

        MAX_GAS_PRICE = gasLimit;

    }

    function computeAllowedInvestment(uint256 investment, address investor) public constant returns (uint256) {

        if (investorLimit == 0) {

            return investment;

        }

        uint256 allowed = investment;

        /**
        * See if the investor's sum gets past the limit, and if so,
        * set the investor's total investment to max
        */

        uint256 storageWei = _storage.getInvestorWei(investor);

        require(storageWei < investorLimit);

        if (allowed.add(storageWei) > investorLimit) {

            allowed = investorLimit.sub(storageWei);


        }

        return allowed;

    }

    function checkIfBonusDay(uint256 _day, uint256 _month, uint256 _year) public constant returns (uint256) {

        uint256 key = _year.mul(100).add(_month).mul(100).add(_day);

        if (activeDays[key] != 0) {

            return activeDays[key];

        } else {

            return 0;

        }
                
    }

    function buyTokens() public payable validGasPrice hatch {

        require(msg.value > 0);
        require(rate != 0);
        require(_storage != CrowdsaleStorage(0));

        uint256 allowed = computeAllowedInvestment(msg.value, msg.sender);

        //Make necessary checks: the campaign didn't end, the investor is not a contract etc

        if (allowed > weiCap || weiRaised.add(allowed) > weiCap) {

            allowed = weiCap.sub(weiRaised);

        }

        require(allowed > 0);

        require(validPurchase(msg.sender, allowed));

        //Calculate token amount to be created
        uint256 tokens = tokensPerInvestment(msg.value);

        //Add the investment to wei raised
        weiRaised = weiRaised.add(allowed);

        //Update investor's info
        _storage.addInvestment(msg.sender, allowed, tokens);

        //Broadcast event
        TokenPurchase(msg.sender, allowed, tokens);

        tokens = 0;

        //Send back ether if the investor sent above the limit
        if (msg.value != allowed) {

            msg.sender.transfer(msg.value.sub(allowed));

        }

    }

    function changeBonusForDate(uint256 _day, uint256 _month, uint256 _year, uint256 newBonus) public onlyOwner {

        uint256 composedTimestamp = _year.mul(100).add(_month).mul(100).add(_day);

        activeDays[composedTimestamp] = newBonus;

    }

    function tokensPerInvestment(uint256 _investment) public constant returns (uint256) {

        uint256 _bonus = checkIfBonusDay(dateTime.getDay(now), dateTime.getMonth(now), dateTime.getYear(now));

        //Compute the bonus for each investment
        uint256 bonusRate = getBonusRate(_bonus);

        //Calculate token amount to be created
        uint256 tokens = (bonusRate * _investment) / oneEther;

        return tokens;

    }

    function getCurrentTimestamp() public constant returns (uint256) {

        return now;

    }

    function getBonusRate(uint256 bonus) public constant returns (uint256) {

        if (bonus == 0) {

            return rate;

        } else {

            return rate + (rate * bonus / 100);

        }

    }

    //We always tax the withdrawal with baseRate + 20% bonus to be withdrawn from token amount

    function refundInvestment(uint256 etherAmount) public refundCondition {

        require(etherAmount > 0);
        require(_storage != CrowdsaleStorage(0));
        require(_storage.getInvestorWei(msg.sender) >= etherAmount.mul(oneEther));

        _storage.withdrawInvestment(msg.sender, etherAmount * oneEther, etherAmount * getBonusRate(20));

        weiRaised = weiRaised.sub(etherAmount * oneEther);

        msg.sender.transfer(etherAmount * oneEther);

    }

    function safeWithdrawal() public afterDeadline onlyOwner hatch {

        require(wallet != address(0));

        if (weiRaised > 0) {

            wallet.transfer(weiRaised);

            TransferredToWallet(weiRaised);

        }

    }

    function distributeTokens(address investor) public onlyOwner afterDeadline {

        require(_storage != CrowdsaleStorage(0));

        uint256 investorWei = _storage.getInvestorWei(investor);

        require(investor != address(0));
        require(investorWei > 0);

        uint256 tokensToSend = _storage.getInvestorTokens(investor);

        _storage.withdrawInvestment(investor, investorWei, tokensToSend);

        token.allocateTokens(investor, tokensToSend);

        AllocateTokens(msg.sender, investor, tokensToSend);

    }

    function claimTokens() public afterDeadline {

        require(_storage != CrowdsaleStorage(0));

        uint256 investorWei = _storage.getInvestorWei(msg.sender);

        require(investorWei > 0);

        uint256 tokensToSend = _storage.getInvestorTokens(msg.sender);

        _storage.withdrawInvestment(msg.sender, investorWei, tokensToSend);

        token.allocateTokens(msg.sender, tokensToSend);

        AllocateTokens(msg.sender, msg.sender, tokensToSend);

    }

    function validPurchase(address investor, uint256 allowed) internal returns (bool) {
        uint256 current = now;
        bool withinPeriod = current >= startTime && current <= endTime;
        bool withinCap = weiRaised.add(allowed) <= weiCap;
        bool investorIsContract = isContract(investor);
        return withinCap && withinPeriod && !paused && !investorIsContract;
    }

    function isContract(address _addr) internal constant returns (bool is_contract) {

      uint length;

      assembly {
            //retrieve the size of the code on target address, this needs assembly
            length := extcodesize(_addr)
      }

      return (length > 0);

    }

    function escapeHatch() public onlyOwner {

        if (blockAttack == 0) {

            blockAttack = 1;

        } else {

            blockAttack = 0;

        }

    }

    function investorInterfaceData() public constant returns (uint256, uint256, uint256, uint256) {

        return (startTime, endTime, this.balance, weiCap);

    }

}
