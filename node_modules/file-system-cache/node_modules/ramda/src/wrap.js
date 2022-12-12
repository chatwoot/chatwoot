var _concat = require('./internal/_concat');
var _curry2 = require('./internal/_curry2');
var curryN = require('./curryN');


/**
 * Wrap a function inside another to allow you to make adjustments to the
 * parameters, or do other processing either before the internal function is
 * called or with its results.
 *
 * @func
 * @memberOf R
 * @since v0.1.0
 * @category Function
 * @sig (a... -> b) -> ((a... -> b) -> a... -> c) -> (a... -> c)
 * @param {Function} fn The function to wrap.
 * @param {Function} wrapper The wrapper function.
 * @return {Function} The wrapped function.
 * @example
 *
 *      var greet = name => 'Hello ' + name;
 *
 *      var shoutedGreet = R.wrap(greet, (gr, name) => gr(name).toUpperCase());
 *
 *      shoutedGreet("Kathy"); //=> "HELLO KATHY"
 *
 *      var shortenedGreet = R.wrap(greet, function(gr, name) {
 *        return gr(name.substring(0, 3));
 *      });
 *      shortenedGreet("Robert"); //=> "Hello Rob"
 */
module.exports = _curry2(function wrap(fn, wrapper) {
  return curryN(fn.length, function() {
    return wrapper.apply(this, _concat([fn], arguments));
  });
});
