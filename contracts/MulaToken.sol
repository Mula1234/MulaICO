pragma solidity ^0.4.17;

/// @author Stefan Ionescu - <stefanionescu@protonmail.com>

import "contracts/libraries/SafeMath.sol";
import "contracts/Owned.sol";
import "contracts/storage/MUTStorage.sol";
import "contracts/interfaces/MulaTokenInterface.sol";

contract MulaToken is MulaTokenInterface {
  
    using SafeMath for uint256;

    Owned private owned;
    MUTStorage _storage;

    string public name = "MULA COIN";
    string public symbol = "MUT";

    uint256 public decimals = 18;
    uint256 public totalSupply = 0;
    uint256 public currentlyInCirculation = 0;
    uint256 blockAttack = 0;

    address internal controller;

    address internal stakeAddress;

    address private upgradedContract;

    modifier onlyAllowedAddresses {
        require(msg.sender == owned.getOwner() || controller == msg.sender);
        _;
    }

    modifier onlyOwner {

        require(msg.sender == owned.getOwner());
        _;

    }

    modifier hatch() {

        require(blockAttack == 0);
        _;

    }

    function tokenFallback(address _from, uint _value, bytes _data) public {
    
      require(msg.sender == stakeAddress);
      require(_storage != MUTStorage(0));

      _storage.increaseMUTBalance(_from, _value);

      currentlyInCirculation = currentlyInCirculation.add(_value);
      
      FallbackData(_data);
    
    }

    function transfer(address _to, uint256 _value, bytes _data) public hatch returns (bool) {
    
      require(_to != address(0));
      require(_value <= _storage.getBalance(msg.sender));
      require(_storage != MUTStorage(0));

      if (_to != address(0) && _to == upgradedContract) {

            MulaTokenInterface upgrade = MulaTokenInterface(_to);
            upgrade.tokenFallback(msg.sender, _value, _data);

            _storage.decreaseMUTBalance(msg.sender, _value);

            currentlyInCirculation = currentlyInCirculation.sub(_value);

            Upgraded(msg.sender, _value);

            return true;

        } else { 

          return transferToAddress(_to, _value, _data);

        }

    }

    function MulaToken(address _owned, uint256 mintedTokens, string _name, string _symbol, uint256 _decimals) {

        owned = Owned(_owned);
        totalSupply = mintedTokens;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

    }

    function initialize(address _storageAddr, address _controller) public onlyOwner {

        _storage = MUTStorage(_storageAddr);

        controller = _controller;

    }

    function changeMUTStorage(address _storageAddr) public onlyOwner {

        _storage = MUTStorage(_storageAddr);

    }

    function allowUpgrade(address _upgradeAddr) public onlyOwner {

        upgradedContract = _upgradeAddr;

    }

    function changeOwned(address _owned) public onlyOwner {

        owned = Owned(_owned);

    }

    function changeController(address _controller) public onlyOwner {

        controller = _controller;

    }

    function getName() public constant returns (string) {

        return name;

    }

    function getSymbol() public constant returns (string) {

        return symbol;

    }

    function getDecimals() public constant returns (uint256) {

        return decimals;

    }

    function getTotalSupply() public constant returns (uint256) {
        return totalSupply;
    }

    function isContract(address _addr) private constant returns (bool is_contract) {
      
        uint length;

        assembly {
                //retrieve the size of the code on target address, this needs assembly
                length := extcodesize(_addr)
        }

        return (length > 0);

    }

    function balanceOf(address _owner) public constant returns (uint256 balance) {
        
        require(_storage != MUTStorage(0));
        
        return _storage.getBalance(_owner);
        
    }

    function addToBalance(address _to, uint256 _amount) public hatch onlyAllowedAddresses {

        require(_storage != MUTStorage(0));

        _storage.increaseMUTBalance(_to, _amount);

    }

    function increaseCirculation(uint256 _amount) public hatch onlyAllowedAddresses {

        require(currentlyInCirculation.add(_amount) <= totalSupply);

        currentlyInCirculation = currentlyInCirculation.add(_amount);

    }

    function transferToAddress(address _to, uint _value, bytes _data) internal hatch returns (bool success) {
    
        if (balanceOf(msg.sender) < _value) 
            revert();

        require(_storage != MUTStorage(0));
    
        _storage.decreaseMUTBalance(msg.sender, _value);
        _storage.increaseMUTBalance(_to, _value);
        Transfer(msg.sender, _to, _value, _data);
        return true;

    }

    function escapeHatch() public onlyOwner {

        if (blockAttack == 0) {

            blockAttack = 1;

        } else {

            blockAttack = 0;

        }
            
    }

}