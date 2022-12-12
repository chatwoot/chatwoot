/**
 * Secure random string generator with custom alphabet.
 *
 * Alphabet must contain 256 symbols or less. Otherwise, the generator
 * will not be secure.
 *
 * @param {asyncGenerator} random The random bytes generator.
 * @param {string} alphabet Symbols to be used in new random string.
 * @param {size} size The number of symbols in new random string.
 *
 * @return {Promise} Promise with random string.
 *
 * @example
 * const formatAsync = require('nanoid/async/format')
 *
 * function random (size) {
 *   const result = []
 *   for (let i = 0; i < size; i++) {
 *     result.push(randomByte())
 *   }
 *   return Promise.resolve(result)
 * }
 *
 * formatAsync(random, "abcdef", 5).then(id => {
 *   model.id = id //=> "fbaef"
 * })
 *
 * @name formatAsync
 * @function
 */
module.exports = function (random, alphabet, size) {
  // We can’t use bytes bigger than the alphabet. To make bytes values closer
  // to the alphabet, we apply bitmask on them. We look for the closest
  // `2 ** x - 1` number, which will be bigger than alphabet size. If we have
  // 30 symbols in the alphabet, we will take 31 (00011111).
  var mask = (2 << 31 - Math.clz32((alphabet.length - 1) | 1)) - 1
  // Bitmask is not a perfect solution (in our example it will pass 31 bytes,
  // which is bigger than the alphabet). As a result, we will need more bytes,
  // than ID size, because we will refuse bytes bigger than the alphabet.

  // Every hardware random generator call is costly,
  // because we need to wait for entropy collection. This is why often it will
  // be faster to ask for few extra bytes in advance, to avoid additional calls.

  // Here we calculate how many random bytes should we call in advance.
  // It depends on ID length, mask / alphabet size and magic number 1.6
  // (which was selected according benchmarks).
  var step = Math.ceil(1.6 * mask * size / alphabet.length)

  function tick (id) {
    return random(step).then(function (bytes) {
      // Compact alternative for `for (var i = 0; i < step; i++)`
      var i = step
      while (i--) {
        // If random byte is bigger than alphabet even after bitmask,
        // we refuse it by `|| ''`.
        id += alphabet[bytes[i] & mask] || ''
        // More compact than `id.length + 1 === size`
        if (id.length === +size) return id
      }
      return tick(id)
    })
  }

  return tick('')
}

/**
 * @callback asyncGenerator
 * @param {number} bytes The number of bytes to generate.
 * @return {Promise} Promise with array of random bytes.
 */
