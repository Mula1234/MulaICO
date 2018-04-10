pragma solidity ^0.4.17;

/// @author Stefan Ionescu - <stefanionescu@protonmail.com>

import "contracts/Owned.sol";
import "contracts/interfaces/MulaTokenInterface.sol";
import "contracts/interfaces/TokenControllerInterface.sol";

contract TokenController is TokenControllerInterface {

    MulaTokenInterface internal MulaToken;
    Owned private owned;

    address private crowdsale;

    modifier acceptedOwners() {
        require(msg.sender == owned.getOwner() || crowdsale == msg.sender);
        _;
    }

    modifier onlyOwner() {

        require(msg.sender == owned.getOwner());
        _;

    }

    function TokenController(address _owned) {

        owned = Owned(_owned);

    }

    function() payable {

        revert();

    }

    function initialize(address _Mula, address _crowdsale) public onlyOwner {

        MulaToken = MulaTokenInterface(_Mula);

        crowdsale = _crowdsale;

    }

    function changeHYPToken(address _Mula) public onlyOwner {

        MulaToken = MulaTokenInterface(_Mula);

    }

    function changeOwned(address _owned) public onlyOwner {

        owned = Owned(_owned);

    }

    function changeCrowdsale(address _crowdsale) public onlyOwner {

        crowdsale = _crowdsale;

    }

    function allocateTokens(address _to, uint256 _amount) public acceptedOwners returns (bool) {
        MulaToken.increaseCirculation(_amount);
        MulaToken.addToBalance(_to, _amount);
        Allocate(_to, _amount);
        return true;
    }

}
