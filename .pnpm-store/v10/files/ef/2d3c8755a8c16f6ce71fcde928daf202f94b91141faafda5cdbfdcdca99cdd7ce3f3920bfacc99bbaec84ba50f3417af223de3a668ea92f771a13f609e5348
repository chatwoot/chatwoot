'use strict';
var globalThis = require('../internals/global-this');
var uncurryThis = require('../internals/function-uncurry-this-clause');
var arrayBufferByteLength = require('../internals/array-buffer-byte-length');

var ArrayBuffer = globalThis.ArrayBuffer;
var ArrayBufferPrototype = ArrayBuffer && ArrayBuffer.prototype;
var slice = ArrayBufferPrototype && uncurryThis(ArrayBufferPrototype.slice);

module.exports = function (O) {
  if (arrayBufferByteLength(O) !== 0) return false;
  if (!slice) return false;
  try {
    slice(O, 0, 0);
    return false;
  } catch (error) {
    return true;
  }
};
