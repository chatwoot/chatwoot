var crypto = require('crypto')

if (crypto.randomFillSync) {
  // We reuse buffers with the same size to avoid memory fragmentations
  // for better performance
  var buffers = { }
  module.exports = function (bytes) {
    var buffer = buffers[bytes]
    if (!buffer) {
      // `Buffer.allocUnsafe()` faster because it don’t clean memory.
      // We do not need it, since we will fill memory with new bytes anyway.
      buffer = Buffer.allocUnsafe(bytes)
      if (bytes <= 255) buffers[bytes] = buffer
    }
    return crypto.randomFillSync(buffer)
  }
} else {
  module.exports = crypto.randomBytes
}
