pragma solidity ^0.4.17;

import "contracts/interfaces/BaseERC223.sol";

contract ERC223 is BaseERC223 {

    //Change the owner of the contract
    function changeOwned(address _owned) public;

    // Function to access name of token .
    function getName() public constant returns (string);

    // Function to access symbol of token .
    function getSymbol() public constant returns (string);

    // Function to access decimals of token .
    function getDecimals() public constant returns (uint256 _decimals);

    // Function to access total supply of tokens .
    function getTotalSupply() public constant returns (uint256);

    //Check if an address is from a contract
    function isContract(address _addr) private constant returns (bool is_contract);

    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public constant returns (uint256 balance);

    function escapeHatch() public;

}