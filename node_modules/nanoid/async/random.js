var crypto = require('crypto')

if (crypto.randomFill) {
  // `crypto.randomFill()` is a little fatser than `crypto.randomBytes()`,
  // because we can use faster `Buffer.allocUnsafe()`.
  module.exports = function (bytes) {
    return new Promise(function (resolve, reject) {
      // `Buffer.allocUnsafe()` faster because it don’t clean memory.
      // We do not need it, since we will fill memory with new bytes anyway.
      crypto.randomFill(Buffer.allocUnsafe(bytes), function (err, buf) {
        if (err) {
          reject(err)
        } else {
          resolve(buf)
        }
      })
    })
  }
} else {
  module.exports = function (bytes) {
    return new Promise(function (resolve, reject) {
      crypto.randomBytes(bytes, function (err, buf) {
        if (err) {
          reject(err)
        } else {
          resolve(buf)
        }
      })
    })
  }
}
