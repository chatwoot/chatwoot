/*! @name pkcs7 @version 1.0.4 @license Apache-2.0 */
'use strict';

Object.defineProperty(exports, '__esModule', { value: true });

/*
 * pkcs7.pad
 * https://github.com/brightcove/pkcs7
 *
 * Copyright (c) 2014 Brightcove
 * Licensed under the apache2 license.
 */
var PADDING;
/**
 * Returns a new Uint8Array that is padded with PKCS#7 padding.
 *
 * @param plaintext {Uint8Array} the input bytes before encryption
 * @return {Uint8Array} the padded bytes
 * @see http://tools.ietf.org/html/rfc5652
 */

function pad(plaintext) {
  var padding = PADDING[plaintext.byteLength % 16 || 0];
  var result = new Uint8Array(plaintext.byteLength + padding.length);
  result.set(plaintext);
  result.set(padding, plaintext.byteLength);
  return result;
} // pre-define the padding values

PADDING = [[16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16], [15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15], [14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14], [13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13], [12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12], [11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11], [10, 10, 10, 10, 10, 10, 10, 10, 10, 10], [9, 9, 9, 9, 9, 9, 9, 9, 9], [8, 8, 8, 8, 8, 8, 8, 8], [7, 7, 7, 7, 7, 7, 7], [6, 6, 6, 6, 6, 6], [5, 5, 5, 5, 5], [4, 4, 4, 4], [3, 3, 3], [2, 2], [1]];

/**
 * Returns the subarray of a Uint8Array without PKCS#7 padding.
 *
 * @param padded {Uint8Array} unencrypted bytes that have been padded
 * @return {Uint8Array} the unpadded bytes
 * @see http://tools.ietf.org/html/rfc5652
 */
function unpad(padded) {
  return padded.subarray(0, padded.byteLength - padded[padded.byteLength - 1]);
}

var version = "1.0.4";

exports.VERSION = version;
exports.pad = pad;
exports.unpad = unpad;
