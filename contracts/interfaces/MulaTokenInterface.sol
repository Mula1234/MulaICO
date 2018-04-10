pragma solidity ^0.4.17;

/// @author Stefan Ionescu - <stefanionescu@protonmail.com>

import "contracts/interfaces/ERC223.sol";

contract MulaTokenInterface is ERC223 {

    //Change the controller which assigns tokens from the campaign
    function changeController(address _controller) public;

    //Change the storage where we manage MUT
    function changeMUTStorage(address _storageAddr) public;

    //Called by the TokenController; assigning tokens to an address
    function addToBalance(address _to, uint256 _amount) public;

    //After we assign tokens, we increase the total amount of tokens which are available on the market
    function increaseCirculation(uint256 _amount) public;

    //function that is called when transaction target is an address
    function transferToAddress(address _to, uint _value, bytes _data) internal returns (bool success);

    function initialize(address _storageAddr, address _controller) public;

}