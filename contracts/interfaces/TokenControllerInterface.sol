pragma solidity ^0.4.17;

/// @author Stefan Ionescu - <stefanionescu@protonmail.com>

contract TokenControllerInterface {

    event Allocate(address indexed to, uint256 amount);

    //Change the contract where we store token balances
    function changeHYPToken(address _sapien) public;

    //Change the owner of this contract
    function changeOwned(address _owned) public;

    //Change the crowdsale contract from which we call the allocate tokens function for investors
    function changeCrowdsale(address _crowdsale) public;

    //The function which assigns tokens to each investor
    function allocateTokens(address _to, uint256 _amount) returns (bool);

    function initialize(address _hyper, address _crowdsale) public;

}