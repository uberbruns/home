// Quicksort function for sorting arrays

// Function: quicksort()
// Synopsis: Sorts an array of numbers in ascending order.
// Usage:
//   sorted = quicksort(arr);
// Description:
//   Implements the quicksort algorithm to sort an array of numbers in ascending order.
//   Uses the middle element as the pivot and recursively sorts lesser and greater partitions.
// Arguments:
//   arr = Array of numbers to sort
// Returns:
//   Sorted array of numbers in ascending order
// Example:
//   quicksort([5, 2, 8, 1, 9])  // Returns: [1, 2, 5, 8, 9]
// input : list of numbers
// output : sorted list of numbers
function quicksort(arr) = !(len(arr)>0) ? [] : let(
    pivot   = arr[floor(len(arr)/2)],
    lesser  = [ for (y = arr) if (y  < pivot) y ],
    equal   = [ for (y = arr) if (y == pivot) y ],
    greater = [ for (y = arr) if (y  > pivot) y ]
) concat(
    quicksort(lesser), equal, quicksort(greater)
);
