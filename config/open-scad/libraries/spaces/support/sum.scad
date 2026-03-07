// Sum function for calculating sum of array/vector elements

// Function: sum()
// Synopsis: Calculates the sum of all values in an array or vector.
// Usage:
//   total = sum(array);
// Description:
//   Returns the sum of all numeric values in the provided array or vector.
//   Any undefined (undef) values are treated as 0 and don't affect the sum.
//   Works with both simple arrays and nested structures.
// Arguments:
//   arr = Array or vector of numeric values
// Returns:
//   Sum of all values (undef values treated as 0)
// Example:
//   sum([1, 2, 3, 4]);              // Returns 10
//   sum([10, 20, undef, 30]);       // Returns 60
//   sum([5.5, 2.3, 1.2]);           // Returns 9.0
//   sum([]);                        // Returns 0
function sum(arr) =
  len(arr) == 0 ? 0 :
  len(arr) == 1 ? (arr[0] == undef ? 0 : arr[0]) :
  (arr[0] == undef ? 0 : arr[0]) + sum([for (i = [1:len(arr)-1]) arr[i]]);
