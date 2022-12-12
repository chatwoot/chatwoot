"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.oneWayHash = void 0;

var _crypto = require("crypto");

var oneWayHash = function oneWayHash(payload) {
  var hash = (0, _crypto.createHash)('sha256'); // Always prepend the payload value with salt. This ensures the hash is truly
  // one-way.

  hash.update('storybook-telemetry-salt'); // Update is an append operation, not a replacement. The salt from the prior
  // update is still present!

  hash.update(payload);
  return hash.digest('hex');
};

exports.oneWayHash = oneWayHash;