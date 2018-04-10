pragma solidity ^0.4.18;

contract Array256Lib {

  /// @dev Sum vector
  /// @param self Storage array containing uint256 type variables
  /// @return sum The sum of all elements, does not check for overflow

  function sumElements(uint256[] memory self) public view returns(uint256 sum);

  /// @dev Returns the max value in an array.
  /// @param self Storage array containing uint256 type variables
  /// @return maxValue The highest value in the array

  function getMax(uint256[] memory self) public view returns(uint256 maxValue);

  /// @dev Returns the minimum value in an array.
  /// @param self Storage array containing uint256 type variables
  /// @return minValue The highest value in the array

  function getMin(uint256[] memory self) public view returns(uint256 minValue);

  /// @dev Finds the index of a given value in an array
  /// @param self Storage array containing uint256 type variables
  /// @param value The value to search for
  /// @param isSorted True if the array is sorted, false otherwise
  /// @return found True if the value was found, false otherwise
  /// @return index The index of the given value, returns 0 if found is false

  function indexOf(uint256[] memory self, uint256 value, bool isSorted)
           public
           view
           returns(bool found, uint256 index);

  /// @dev Utility function for heapSort
  /// @param index The index of child node
  /// @return pI The parent node index

  function getParentI(uint256 index) private pure returns (uint256 pI);

  /// @dev Utility function for heapSort
  /// @param index The index of parent node
  /// @return lcI The index of left child

  function getLeftChildI(uint256 index) private pure returns (uint256 lcI);

  /// @dev Sorts given array in place
  /// @param self Storage array containing uint256 type variables

  function heapSort(uint256[] memory self) public;

  /// @dev Removes duplicates from a given array.
  /// @param self Storage array containing uint256 type variables

  function uniq(uint256[] memory self) public returns (uint256 length);

}