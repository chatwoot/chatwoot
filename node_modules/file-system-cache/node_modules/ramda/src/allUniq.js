var _curry1 = require('./internal/_curry1');
var _indexOf = require('./internal/_indexOf');


/**
 * Returns `true` if all elements are unique, in `R.equals` terms, otherwise
 * `false`.
 *
 * @func
 * @memberOf R
 * @since v0.18.0
 * @category List
 * @sig [a] -> Boolean
 * @param {Array} list The array to consider.
 * @return {Boolean} `true` if all elements are unique, else `false`.
 * @deprecated since v0.20.0
 * @example
 *
 *      R.allUniq(['1', 1]); //=> true
 *      R.allUniq([1, 1]);   //=> false
 *      R.allUniq([[42], [42]]); //=> false
 */
module.exports = _curry1(function allUniq(list) {
  var len = list.length;
  var idx = 0;
  while (idx < len) {
    if (_indexOf(list, list[idx], idx + 1) >= 0) {
      return false;
    }
    idx += 1;
  }
  return true;
});
