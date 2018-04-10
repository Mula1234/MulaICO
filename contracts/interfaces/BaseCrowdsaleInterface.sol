pragma solidity ^0.4.17;

/// @author Stefan Ionescu - <stefanionescu@protonmail.com>

contract BaseCrowdsaleInterface {

    struct OneDay {

        uint256 day;
        uint256 month;

    }

     /**
     * event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokenPurchase(address indexed purchaser, uint256 value, uint256 amount);

    /**
    * @dev Triggered when we want to withdraw funds to wallet
    */
    event TransferredToWallet(uint256 amount);

    /**
    * Called when investor tokens are allocated
    */
    event AllocateTokens(address sender, address who, uint256 amount);

    //Changing the owner of the contract
    function changeOwned(address _owned) public;

    //Pause campaign in case of bug/attack/anything else
    function pauseContribution() public;

    //Resume campaign
    function resumeContribution() public;

    //Change crowdsale's storage contract
    function changeCrowdsaleStorage(address _storageAddress) public;

    //Change the token controller that allocates the preminted MUT
    function switchTokenController(address _token) public;

    //Change the wallet where we send the funds from investors
    function switchWallet(address _wallet) public;

    function getSaleStart() constant returns (uint256, uint256, uint256);

    //Used by investors to buy tokens
    function buyTokens() public payable;

    //Used by investors to get their tokens after campaign ends
    function claimTokens() public;

    //Check if investor is qualified to invest
    function validPurchase(address investor, uint256 allowed) internal returns (bool);

    //Check if investor is a contract; if it is a contract, we will block them
    function isContract(address _addr) internal constant returns (bool is_contract);

    //Block the majority of functions from being called in case of attack/vulnerability/etc
    function escapeHatch() public;

    //Withdrawing the ether gathered in a wallet after the campaign ends
    function safeWithdrawal() public;

    //Used by owner to distribute tokens to investors in case someone forgets to take their tokens
    function distributeTokens(address investor) public;

}