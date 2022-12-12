var _curry2 = require('./internal/_curry2');

/**
 * Takes a list and returns a list of lists where each sublist's elements are
 * all "equal" according to the provided equality function.
 *
 * @func
 * @memberOf R
 * @since v0.21.0
 * @category List
 * @sig (a, a -> Boolean) -> [a] -> [[a]]
 * @param {Function} fn Function for determining whether two given (adjacent)
 *        elements should be in the same group
 * @param {Array} list The array to group. Also accepts a string, which will be
 *        treated as a list of characters.
 * @return {List} A list that contains sublists of equal elements,
 *         whose concatenations is equal to the original list.
 * @example
 *
 *    groupWith(R.equals, [0, 1, 1, 2, 3, 5, 8, 13, 21])
 *    // [[0], [1, 1], [2, 3, 5, 8, 13, 21]]
 *
 *    groupWith((a, b) => a % 2 === b % 2, [0, 1, 1, 2, 3, 5, 8, 13, 21])
 *    // [[0], [1, 1], [2], [3, 5], [8], [13, 21]]
 *
 *    R.groupWith(R.eqBy(isVowel), 'aestiou')
 *    // ['ae', 'st', 'iou']
 */
module.exports = _curry2(function(fn, list) {
  var res = [];
  var idx = 0;
  var len = list.length;
  while (idx < len) {
    var nextidx = idx + 1;
    while (nextidx < len && fn(list[idx], list[nextidx])) {
      nextidx += 1;
    }
    res.push(list.slice(idx, nextidx));
    idx = nextidx;
  }
  return res;
});
