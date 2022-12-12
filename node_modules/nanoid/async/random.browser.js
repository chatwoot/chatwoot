// This file replaces `async/random.js` in bundlers like webpack or Rollup,
// according to `browser` config in `package.json`.

var crypto = self.crypto || self.msCrypto

module.exports = function (bytes) {
  return Promise.resolve(crypto.getRandomValues(new Uint8Array(bytes)))
}
