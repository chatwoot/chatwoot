var random = require('./random')
var url = require('../url')

/**
 * Generate secure URL-friendly unique ID. Non-blocking version.
 *
 * By default, ID will have 21 symbols to have a collision probability similar
 * to UUID v4.
 *
 * @param {number} [size=21] The number of symbols in ID.
 *
 * @return {Promise} Promise with random string.
 *
 * @example
 * const nanoidAsync = require('nanoid/async')
 * nanoidAsync.then(id => {
 *   model.id = id
 * })
 *
 * @name async
 * @function
 */
module.exports = function (size) {
  size = size || 21
  return random(size).then(function (bytes) {
    var id = ''
    // Compact alternative for `for (var i = 0; i < size; i++)`
    while (size--) {
      // We can’t use bytes bigger than the alphabet. 63 is 00111111 bitmask.
      // This mask reduces random byte 0-255 to 0-63 values.
      // There is no need in `|| ''` and `* 1.6` hacks in here,
      // because bitmask trim bytes exact to alphabet size.
      id += url[bytes[size] & 63]
    }
    return id
  })
}
