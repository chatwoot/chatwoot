var lift = require('./lift');
var not = require('./not');


/**
 * Takes a function `f` and returns a function `g` such that:
 *
 *   - applying `g` to zero or more arguments will give __true__ if applying
 *     the same arguments to `f` gives a logical __false__ value; and
 *
 *   - applying `g` to zero or more arguments will give __false__ if applying
 *     the same arguments to `f` gives a logical __true__ value.
 *
 * `R.complement` will work on all other functors as well.
 *
 * @func
 * @memberOf R
 * @since v0.12.0
 * @category Logic
 * @sig (*... -> *) -> (*... -> Boolean)
 * @param {Function} f
 * @return {Function}
 * @see R.not
 * @example
 *
 *      var isEven = n => n % 2 === 0;
 *      var isOdd = R.complement(isEven);
 *      isOdd(21); //=> true
 *      isOdd(42); //=> false
 */
module.exports = lift(not);
