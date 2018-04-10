pragma solidity ^0.4.17;

/// @author Stefan Ionescu - <stefanionescu@protonmail.com>

import "contracts/Owned.sol";
import "contracts/libraries/SafeMath.sol";

contract MUTStorage {

    using SafeMath for uint256;

    mapping(address => uint256) balances;

    mapping(address => uint256) allowedContracts;

    Owned private owned;

    modifier onlyAllowedContracts {

        require(allowedContracts[msg.sender] == 1);
        _;

    }

    modifier onlyOwner {

        require(msg.sender == owned.getOwner());
        _;

    }

    function MUTStorage(address _owned) {

        owned = Owned(_owned);

    }

    function changeOwner(address _owned) onlyOwner {

        owned = Owned(_owned);

    }

    function addContract(address _contract) onlyOwner {

        allowedContracts[_contract] = 1;

    }

    function deleteContract(address _contract) onlyOwner {

        require(allowedContracts[_contract] == 1);

        allowedContracts[_contract] = 0;

    }

    function getBalance(address _who) public constant returns (uint256) {

        return balances[_who];

    }

    function increaseMUTBalance(address _who, uint256 _amount) onlyAllowedContracts {

        require(_amount > 0);
        require(_who != address(0));

        balances[_who] = balances[_who].add(_amount);

    }

    function decreaseMUTBalance(address _who, uint256 _amount) onlyAllowedContracts {

        require(_amount > 0);
        require(_who != address(0));
        require(balances[_who] >= _amount);

        balances[_who] = balances[_who].sub(_amount);

    }

}