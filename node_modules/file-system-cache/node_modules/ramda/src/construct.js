var _curry1 = require('./internal/_curry1');
var constructN = require('./constructN');


/**
 * Wraps a constructor function inside a curried function that can be called
 * with the same arguments and returns the same type.
 *
 * @func
 * @memberOf R
 * @since v0.1.0
 * @category Function
 * @sig (* -> {*}) -> (* -> {*})
 * @param {Function} Fn The constructor function to wrap.
 * @return {Function} A wrapped, curried constructor function.
 * @example
 *
 *      // Constructor function
 *      var Widget = config => {
 *        // ...
 *      };
 *      Widget.prototype = {
 *        // ...
 *      };
 *      var allConfigs = [
 *        // ...
 *      ];
 *      R.map(R.construct(Widget), allConfigs); // a list of Widgets
 */
module.exports = _curry1(function construct(Fn) {
  return constructN(Fn.length, Fn);
});
