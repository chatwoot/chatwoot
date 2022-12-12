var _curry2 = require('./internal/_curry2');
var _dispatchable = require('./internal/_dispatchable');
var _dropLastWhile = require('./internal/_dropLastWhile');
var _xdropLastWhile = require('./internal/_xdropLastWhile');


/**
 * Returns a new list containing all but last the`n` elements of a given list,
 * passing each value from the right to the supplied predicate function,
 * skipping elements while the predicate function returns `true`. The predicate
 * function is passed one argument: (value)*.
 *
 * @func
 * @memberOf R
 * @since v0.16.0
 * @category List
 * @sig (a -> Boolean) -> [a] -> [a]
 * @param {Function} fn The function called per iteration.
 * @param {Array} list The collection to iterate over.
 * @return {Array} A new array.
 * @see R.takeLastWhile, R.addIndex
 * @example
 *
 *      var lteThree = x => x <= 3;
 *
 *      R.dropLastWhile(lteThree, [1, 2, 3, 4, 3, 2, 1]); //=> [1, 2, 3, 4]
 */
module.exports = _curry2(_dispatchable('dropLastWhile', _xdropLastWhile, _dropLastWhile));
