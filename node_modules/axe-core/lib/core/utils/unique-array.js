/**
 * Creates an array without duplicate values from 2 array inputs
 * @param {Array} arr1 First array
 * @param {Array} arr2 Second array
 * @return {Array}
 */
function uniqueArray(arr1, arr2) {
  return arr1.concat(arr2).filter((elem, pos, arr) => {
    return arr.indexOf(elem) === pos;
  });
}

export default uniqueArray;
