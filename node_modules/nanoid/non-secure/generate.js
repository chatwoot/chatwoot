/**
 * Generate URL-friendly unique ID. This method use non-secure predictable
 * random generator with bigger collision probability.
 *
 * @param {string} alphabet Symbols to be used in ID.
 * @param {number} [size=21] The number of symbols in ID.
 *
 * @return {string} Random string.
 *
 * @example
 * const nanoid = require('nanoid/non-secure')
 * model.id = nanoid() //=> "Uakgb_J5m9g-0JDMbcJqL"
 *
 * @name nonSecure
 * @function
 */
module.exports = function (alphabet, size) {
  size = size || 21
  var id = ''
  // Compact alternative for `for (var i = 0; i < size; i++)`
  while (size--) {
    // `| 0` is compact and faster alternative for `Math.floor()`
    id += alphabet[Math.random() * alphabet.length | 0]
  }
  return id
}
