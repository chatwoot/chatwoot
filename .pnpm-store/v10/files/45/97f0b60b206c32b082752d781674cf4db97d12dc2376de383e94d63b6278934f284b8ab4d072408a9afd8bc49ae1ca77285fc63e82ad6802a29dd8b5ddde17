/*! @name aes-decrypter @version 3.1.2 @license Apache-2.0 */
(function (global, factory) {
  typeof exports === 'object' && typeof module !== 'undefined' ? factory(exports) :
  typeof define === 'function' && define.amd ? define(['exports'], factory) :
  (global = typeof globalThis !== 'undefined' ? globalThis : global || self, factory(global.aesDecrypter = {}));
}(this, (function (exports) { 'use strict';

  function _defineProperties(target, props) {
    for (var i = 0; i < props.length; i++) {
      var descriptor = props[i];
      descriptor.enumerable = descriptor.enumerable || false;
      descriptor.configurable = true;
      if ("value" in descriptor) descriptor.writable = true;
      Object.defineProperty(target, descriptor.key, descriptor);
    }
  }

  function _createClass(Constructor, protoProps, staticProps) {
    if (protoProps) _defineProperties(Constructor.prototype, protoProps);
    if (staticProps) _defineProperties(Constructor, staticProps);
    return Constructor;
  }

  var createClass = _createClass;

  /**
   * @file aes.js
   *
   * This file contains an adaptation of the AES decryption algorithm
   * from the Standford Javascript Cryptography Library. That work is
   * covered by the following copyright and permissions notice:
   *
   * Copyright 2009-2010 Emily Stark, Mike Hamburg, Dan Boneh.
   * All rights reserved.
   *
   * Redistribution and use in source and binary forms, with or without
   * modification, are permitted provided that the following conditions are
   * met:
   *
   * 1. Redistributions of source code must retain the above copyright
   *    notice, this list of conditions and the following disclaimer.
   *
   * 2. Redistributions in binary form must reproduce the above
   *    copyright notice, this list of conditions and the following
   *    disclaimer in the documentation and/or other materials provided
   *    with the distribution.
   *
   * THIS SOFTWARE IS PROVIDED BY THE AUTHORS ``AS IS'' AND ANY EXPRESS OR
   * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
   * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
   * DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> OR CONTRIBUTORS BE
   * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
   * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
   * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
   * BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
   * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
   * OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
   * IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
   *
   * The views and conclusions contained in the software and documentation
   * are those of the authors and should not be interpreted as representing
   * official policies, either expressed or implied, of the authors.
   */

  /**
   * Expand the S-box tables.
   *
   * @private
   */
  var precompute = function precompute() {
    var tables = [[[], [], [], [], []], [[], [], [], [], []]];
    var encTable = tables[0];
    var decTable = tables[1];
    var sbox = encTable[4];
    var sboxInv = decTable[4];
    var i;
    var x;
    var xInv;
    var d = [];
    var th = [];
    var x2;
    var x4;
    var x8;
    var s;
    var tEnc;
    var tDec; // Compute double and third tables

    for (i = 0; i < 256; i++) {
      th[(d[i] = i << 1 ^ (i >> 7) * 283) ^ i] = i;
    }

    for (x = xInv = 0; !sbox[x]; x ^= x2 || 1, xInv = th[xInv] || 1) {
      // Compute sbox
      s = xInv ^ xInv << 1 ^ xInv << 2 ^ xInv << 3 ^ xInv << 4;
      s = s >> 8 ^ s & 255 ^ 99;
      sbox[x] = s;
      sboxInv[s] = x; // Compute MixColumns

      x8 = d[x4 = d[x2 = d[x]]];
      tDec = x8 * 0x1010101 ^ x4 * 0x10001 ^ x2 * 0x101 ^ x * 0x1010100;
      tEnc = d[s] * 0x101 ^ s * 0x1010100;

      for (i = 0; i < 4; i++) {
        encTable[i][x] = tEnc = tEnc << 24 ^ tEnc >>> 8;
        decTable[i][s] = tDec = tDec << 24 ^ tDec >>> 8;
      }
    } // Compactify. Considerable speedup on Firefox.


    for (i = 0; i < 5; i++) {
      encTable[i] = encTable[i].slice(0);
      decTable[i] = decTable[i].slice(0);
    }

    return tables;
  };

  var aesTables = null;
  /**
   * Schedule out an AES key for both encryption and decryption. This
   * is a low-level class. Use a cipher mode to do bulk encryption.
   *
   * @class AES
   * @param key {Array} The key as an array of 4, 6 or 8 words.
   */

  var AES = /*#__PURE__*/function () {
    function AES(key) {
      /**
      * The expanded S-box and inverse S-box tables. These will be computed
      * on the client so that we don't have to send them down the wire.
      *
      * There are two tables, _tables[0] is for encryption and
      * _tables[1] is for decryption.
      *
      * The first 4 sub-tables are the expanded S-box with MixColumns. The
      * last (_tables[01][4]) is the S-box itself.
      *
      * @private
      */
      // if we have yet to precompute the S-box tables
      // do so now
      if (!aesTables) {
        aesTables = precompute();
      } // then make a copy of that object for use


      this._tables = [[aesTables[0][0].slice(), aesTables[0][1].slice(), aesTables[0][2].slice(), aesTables[0][3].slice(), aesTables[0][4].slice()], [aesTables[1][0].slice(), aesTables[1][1].slice(), aesTables[1][2].slice(), aesTables[1][3].slice(), aesTables[1][4].slice()]];
      var i;
      var j;
      var tmp;
      var sbox = this._tables[0][4];
      var decTable = this._tables[1];
      var keyLen = key.length;
      var rcon = 1;

      if (keyLen !== 4 && keyLen !== 6 && keyLen !== 8) {
        throw new Error('Invalid aes key size');
      }

      var encKey = key.slice(0);
      var decKey = [];
      this._key = [encKey, decKey]; // schedule encryption keys

      for (i = keyLen; i < 4 * keyLen + 28; i++) {
        tmp = encKey[i - 1]; // apply sbox

        if (i % keyLen === 0 || keyLen === 8 && i % keyLen === 4) {
          tmp = sbox[tmp >>> 24] << 24 ^ sbox[tmp >> 16 & 255] << 16 ^ sbox[tmp >> 8 & 255] << 8 ^ sbox[tmp & 255]; // shift rows and add rcon

          if (i % keyLen === 0) {
            tmp = tmp << 8 ^ tmp >>> 24 ^ rcon << 24;
            rcon = rcon << 1 ^ (rcon >> 7) * 283;
          }
        }

        encKey[i] = encKey[i - keyLen] ^ tmp;
      } // schedule decryption keys


      for (j = 0; i; j++, i--) {
        tmp = encKey[j & 3 ? i : i - 4];

        if (i <= 4 || j < 4) {
          decKey[j] = tmp;
        } else {
          decKey[j] = decTable[0][sbox[tmp >>> 24]] ^ decTable[1][sbox[tmp >> 16 & 255]] ^ decTable[2][sbox[tmp >> 8 & 255]] ^ decTable[3][sbox[tmp & 255]];
        }
      }
    }
    /**
     * Decrypt 16 bytes, specified as four 32-bit words.
     *
     * @param {number} encrypted0 the first word to decrypt
     * @param {number} encrypted1 the second word to decrypt
     * @param {number} encrypted2 the third word to decrypt
     * @param {number} encrypted3 the fourth word to decrypt
     * @param {Int32Array} out the array to write the decrypted words
     * into
     * @param {number} offset the offset into the output array to start
     * writing results
     * @return {Array} The plaintext.
     */


    var _proto = AES.prototype;

    _proto.decrypt = function decrypt(encrypted0, encrypted1, encrypted2, encrypted3, out, offset) {
      var key = this._key[1]; // state variables a,b,c,d are loaded with pre-whitened data

      var a = encrypted0 ^ key[0];
      var b = encrypted3 ^ key[1];
      var c = encrypted2 ^ key[2];
      var d = encrypted1 ^ key[3];
      var a2;
      var b2;
      var c2; // key.length === 2 ?

      var nInnerRounds = key.length / 4 - 2;
      var i;
      var kIndex = 4;
      var table = this._tables[1]; // load up the tables

      var table0 = table[0];
      var table1 = table[1];
      var table2 = table[2];
      var table3 = table[3];
      var sbox = table[4]; // Inner rounds. Cribbed from OpenSSL.

      for (i = 0; i < nInnerRounds; i++) {
        a2 = table0[a >>> 24] ^ table1[b >> 16 & 255] ^ table2[c >> 8 & 255] ^ table3[d & 255] ^ key[kIndex];
        b2 = table0[b >>> 24] ^ table1[c >> 16 & 255] ^ table2[d >> 8 & 255] ^ table3[a & 255] ^ key[kIndex + 1];
        c2 = table0[c >>> 24] ^ table1[d >> 16 & 255] ^ table2[a >> 8 & 255] ^ table3[b & 255] ^ key[kIndex + 2];
        d = table0[d >>> 24] ^ table1[a >> 16 & 255] ^ table2[b >> 8 & 255] ^ table3[c & 255] ^ key[kIndex + 3];
        kIndex += 4;
        a = a2;
        b = b2;
        c = c2;
      } // Last round.


      for (i = 0; i < 4; i++) {
        out[(3 & -i) + offset] = sbox[a >>> 24] << 24 ^ sbox[b >> 16 & 255] << 16 ^ sbox[c >> 8 & 255] << 8 ^ sbox[d & 255] ^ key[kIndex++];
        a2 = a;
        a = b;
        b = c;
        c = d;
        d = a2;
      }
    };

    return AES;
  }();

  function _inheritsLoose(subClass, superClass) {
    subClass.prototype = Object.create(superClass.prototype);
    subClass.prototype.constructor = subClass;
    subClass.__proto__ = superClass;
  }

  var inheritsLoose = _inheritsLoose;

  /**
   * @file stream.js
   */

  /**
   * A lightweight readable stream implemention that handles event dispatching.
   *
   * @class Stream
   */
  var Stream = /*#__PURE__*/function () {
    function Stream() {
      this.listeners = {};
    }
    /**
     * Add a listener for a specified event type.
     *
     * @param {string} type the event name
     * @param {Function} listener the callback to be invoked when an event of
     * the specified type occurs
     */


    var _proto = Stream.prototype;

    _proto.on = function on(type, listener) {
      if (!this.listeners[type]) {
        this.listeners[type] = [];
      }

      this.listeners[type].push(listener);
    }
    /**
     * Remove a listener for a specified event type.
     *
     * @param {string} type the event name
     * @param {Function} listener  a function previously registered for this
     * type of event through `on`
     * @return {boolean} if we could turn it off or not
     */
    ;

    _proto.off = function off(type, listener) {
      if (!this.listeners[type]) {
        return false;
      }

      var index = this.listeners[type].indexOf(listener); // TODO: which is better?
      // In Video.js we slice listener functions
      // on trigger so that it does not mess up the order
      // while we loop through.
      //
      // Here we slice on off so that the loop in trigger
      // can continue using it's old reference to loop without
      // messing up the order.

      this.listeners[type] = this.listeners[type].slice(0);
      this.listeners[type].splice(index, 1);
      return index > -1;
    }
    /**
     * Trigger an event of the specified type on this stream. Any additional
     * arguments to this function are passed as parameters to event listeners.
     *
     * @param {string} type the event name
     */
    ;

    _proto.trigger = function trigger(type) {
      var callbacks = this.listeners[type];

      if (!callbacks) {
        return;
      } // Slicing the arguments on every invocation of this method
      // can add a significant amount of overhead. Avoid the
      // intermediate object creation for the common case of a
      // single callback argument


      if (arguments.length === 2) {
        var length = callbacks.length;

        for (var i = 0; i < length; ++i) {
          callbacks[i].call(this, arguments[1]);
        }
      } else {
        var args = Array.prototype.slice.call(arguments, 1);
        var _length = callbacks.length;

        for (var _i = 0; _i < _length; ++_i) {
          callbacks[_i].apply(this, args);
        }
      }
    }
    /**
     * Destroys the stream and cleans up.
     */
    ;

    _proto.dispose = function dispose() {
      this.listeners = {};
    }
    /**
     * Forwards all `data` events on this stream to the destination stream. The
     * destination stream should provide a method `push` to receive the data
     * events as they arrive.
     *
     * @param {Stream} destination the stream that will receive all `data` events
     * @see http://nodejs.org/api/stream.html#stream_readable_pipe_destination_options
     */
    ;

    _proto.pipe = function pipe(destination) {
      this.on('data', function (data) {
        destination.push(data);
      });
    };

    return Stream;
  }();

  /**
   * A wrapper around the Stream class to use setTimeout
   * and run stream "jobs" Asynchronously
   *
   * @class AsyncStream
   * @extends Stream
   */

  var AsyncStream = /*#__PURE__*/function (_Stream) {
    inheritsLoose(AsyncStream, _Stream);

    function AsyncStream() {
      var _this;

      _this = _Stream.call(this, Stream) || this;
      _this.jobs = [];
      _this.delay = 1;
      _this.timeout_ = null;
      return _this;
    }
    /**
     * process an async job
     *
     * @private
     */


    var _proto = AsyncStream.prototype;

    _proto.processJob_ = function processJob_() {
      this.jobs.shift()();

      if (this.jobs.length) {
        this.timeout_ = setTimeout(this.processJob_.bind(this), this.delay);
      } else {
        this.timeout_ = null;
      }
    }
    /**
     * push a job into the stream
     *
     * @param {Function} job the job to push into the stream
     */
    ;

    _proto.push = function push(job) {
      this.jobs.push(job);

      if (!this.timeout_) {
        this.timeout_ = setTimeout(this.processJob_.bind(this), this.delay);
      }
    };

    return AsyncStream;
  }(Stream);

  /*! @name pkcs7 @version 1.0.4 @license Apache-2.0 */
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

  /**
   * Convert network-order (big-endian) bytes into their little-endian
   * representation.
   */

  var ntoh = function ntoh(word) {
    return word << 24 | (word & 0xff00) << 8 | (word & 0xff0000) >> 8 | word >>> 24;
  };
  /**
   * Decrypt bytes using AES-128 with CBC and PKCS#7 padding.
   *
   * @param {Uint8Array} encrypted the encrypted bytes
   * @param {Uint32Array} key the bytes of the decryption key
   * @param {Uint32Array} initVector the initialization vector (IV) to
   * use for the first round of CBC.
   * @return {Uint8Array} the decrypted bytes
   *
   * @see http://en.wikipedia.org/wiki/Advanced_Encryption_Standard
   * @see http://en.wikipedia.org/wiki/Block_cipher_mode_of_operation#Cipher_Block_Chaining_.28CBC.29
   * @see https://tools.ietf.org/html/rfc2315
   */


  var decrypt = function decrypt(encrypted, key, initVector) {
    // word-level access to the encrypted bytes
    var encrypted32 = new Int32Array(encrypted.buffer, encrypted.byteOffset, encrypted.byteLength >> 2);
    var decipher = new AES(Array.prototype.slice.call(key)); // byte and word-level access for the decrypted output

    var decrypted = new Uint8Array(encrypted.byteLength);
    var decrypted32 = new Int32Array(decrypted.buffer); // temporary variables for working with the IV, encrypted, and
    // decrypted data

    var init0;
    var init1;
    var init2;
    var init3;
    var encrypted0;
    var encrypted1;
    var encrypted2;
    var encrypted3; // iteration variable

    var wordIx; // pull out the words of the IV to ensure we don't modify the
    // passed-in reference and easier access

    init0 = initVector[0];
    init1 = initVector[1];
    init2 = initVector[2];
    init3 = initVector[3]; // decrypt four word sequences, applying cipher-block chaining (CBC)
    // to each decrypted block

    for (wordIx = 0; wordIx < encrypted32.length; wordIx += 4) {
      // convert big-endian (network order) words into little-endian
      // (javascript order)
      encrypted0 = ntoh(encrypted32[wordIx]);
      encrypted1 = ntoh(encrypted32[wordIx + 1]);
      encrypted2 = ntoh(encrypted32[wordIx + 2]);
      encrypted3 = ntoh(encrypted32[wordIx + 3]); // decrypt the block

      decipher.decrypt(encrypted0, encrypted1, encrypted2, encrypted3, decrypted32, wordIx); // XOR with the IV, and restore network byte-order to obtain the
      // plaintext

      decrypted32[wordIx] = ntoh(decrypted32[wordIx] ^ init0);
      decrypted32[wordIx + 1] = ntoh(decrypted32[wordIx + 1] ^ init1);
      decrypted32[wordIx + 2] = ntoh(decrypted32[wordIx + 2] ^ init2);
      decrypted32[wordIx + 3] = ntoh(decrypted32[wordIx + 3] ^ init3); // setup the IV for the next round

      init0 = encrypted0;
      init1 = encrypted1;
      init2 = encrypted2;
      init3 = encrypted3;
    }

    return decrypted;
  };
  /**
   * The `Decrypter` class that manages decryption of AES
   * data through `AsyncStream` objects and the `decrypt`
   * function
   *
   * @param {Uint8Array} encrypted the encrypted bytes
   * @param {Uint32Array} key the bytes of the decryption key
   * @param {Uint32Array} initVector the initialization vector (IV) to
   * @param {Function} done the function to run when done
   * @class Decrypter
   */


  var Decrypter = /*#__PURE__*/function () {
    function Decrypter(encrypted, key, initVector, done) {
      var step = Decrypter.STEP;
      var encrypted32 = new Int32Array(encrypted.buffer);
      var decrypted = new Uint8Array(encrypted.byteLength);
      var i = 0;
      this.asyncStream_ = new AsyncStream(); // split up the encryption job and do the individual chunks asynchronously

      this.asyncStream_.push(this.decryptChunk_(encrypted32.subarray(i, i + step), key, initVector, decrypted));

      for (i = step; i < encrypted32.length; i += step) {
        initVector = new Uint32Array([ntoh(encrypted32[i - 4]), ntoh(encrypted32[i - 3]), ntoh(encrypted32[i - 2]), ntoh(encrypted32[i - 1])]);
        this.asyncStream_.push(this.decryptChunk_(encrypted32.subarray(i, i + step), key, initVector, decrypted));
      } // invoke the done() callback when everything is finished


      this.asyncStream_.push(function () {
        // remove pkcs#7 padding from the decrypted bytes
        done(null, unpad(decrypted));
      });
    }
    /**
     * a getter for step the maximum number of bytes to process at one time
     *
     * @return {number} the value of step 32000
     */


    var _proto = Decrypter.prototype;

    /**
     * @private
     */
    _proto.decryptChunk_ = function decryptChunk_(encrypted, key, initVector, decrypted) {
      return function () {
        var bytes = decrypt(encrypted, key, initVector);
        decrypted.set(bytes, encrypted.byteOffset);
      };
    };

    createClass(Decrypter, null, [{
      key: "STEP",
      get: function get() {
        // 4 * 8000;
        return 32000;
      }
    }]);

    return Decrypter;
  }();

  exports.AsyncStream = AsyncStream;
  exports.Decrypter = Decrypter;
  exports.decrypt = decrypt;

  Object.defineProperty(exports, '__esModule', { value: true });

})));
