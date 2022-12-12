/**
 * @file decrypter.js
 *
 * An asynchronous implementation of AES-128 CBC decryption with
 * PKCS#7 padding.
 */

import AES from './aes';
import AsyncStream from './async-stream';
import {unpad} from 'pkcs7';

/**
 * Convert network-order (big-endian) bytes into their little-endian
 * representation.
 */
const ntoh = function(word) {
  return (word << 24) |
    ((word & 0xff00) << 8) |
    ((word & 0xff0000) >> 8) |
    (word >>> 24);
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
const decrypt = function(encrypted, key, initVector) {
  // word-level access to the encrypted bytes
  const encrypted32 = new Int32Array(
    encrypted.buffer,
    encrypted.byteOffset,
    encrypted.byteLength >> 2
  );

  const decipher = new AES(Array.prototype.slice.call(key));

  // byte and word-level access for the decrypted output
  const decrypted = new Uint8Array(encrypted.byteLength);
  const decrypted32 = new Int32Array(decrypted.buffer);

  // temporary variables for working with the IV, encrypted, and
  // decrypted data
  let init0;
  let init1;
  let init2;
  let init3;
  let encrypted0;
  let encrypted1;
  let encrypted2;
  let encrypted3;

  // iteration variable
  let wordIx;

  // pull out the words of the IV to ensure we don't modify the
  // passed-in reference and easier access
  init0 = initVector[0];
  init1 = initVector[1];
  init2 = initVector[2];
  init3 = initVector[3];

  // decrypt four word sequences, applying cipher-block chaining (CBC)
  // to each decrypted block
  for (wordIx = 0; wordIx < encrypted32.length; wordIx += 4) {
    // convert big-endian (network order) words into little-endian
    // (javascript order)
    encrypted0 = ntoh(encrypted32[wordIx]);
    encrypted1 = ntoh(encrypted32[wordIx + 1]);
    encrypted2 = ntoh(encrypted32[wordIx + 2]);
    encrypted3 = ntoh(encrypted32[wordIx + 3]);

    // decrypt the block
    decipher.decrypt(
      encrypted0,
      encrypted1,
      encrypted2,
      encrypted3,
      decrypted32,
      wordIx
    );

    // XOR with the IV, and restore network byte-order to obtain the
    // plaintext
    decrypted32[wordIx] = ntoh(decrypted32[wordIx] ^ init0);
    decrypted32[wordIx + 1] = ntoh(decrypted32[wordIx + 1] ^ init1);
    decrypted32[wordIx + 2] = ntoh(decrypted32[wordIx + 2] ^ init2);
    decrypted32[wordIx + 3] = ntoh(decrypted32[wordIx + 3] ^ init3);

    // setup the IV for the next round
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
class Decrypter {
  constructor(encrypted, key, initVector, done) {
    const step = Decrypter.STEP;
    const encrypted32 = new Int32Array(encrypted.buffer);
    const decrypted = new Uint8Array(encrypted.byteLength);
    let i = 0;

    this.asyncStream_ = new AsyncStream();

    // split up the encryption job and do the individual chunks asynchronously
    this.asyncStream_.push(this.decryptChunk_(
      encrypted32.subarray(i, i + step),
      key,
      initVector,
      decrypted
    ));
    for (i = step; i < encrypted32.length; i += step) {
      initVector = new Uint32Array([ntoh(encrypted32[i - 4]),
        ntoh(encrypted32[i - 3]),
        ntoh(encrypted32[i - 2]),
        ntoh(encrypted32[i - 1])]);
      this.asyncStream_.push(this.decryptChunk_(
        encrypted32.subarray(i, i + step),
        key,
        initVector,
        decrypted
      ));
    }
    // invoke the done() callback when everything is finished
    this.asyncStream_.push(function() {
      // remove pkcs#7 padding from the decrypted bytes
      done(null, unpad(decrypted));
    });
  }

  /**
   * a getter for step the maximum number of bytes to process at one time
   *
   * @return {number} the value of step 32000
   */
  static get STEP() {
    // 4 * 8000;
    return 32000;
  }

  /**
   * @private
   */
  decryptChunk_(encrypted, key, initVector, decrypted) {
    return function() {
      const bytes = decrypt(encrypted, key, initVector);

      decrypted.set(bytes, encrypted.byteOffset);
    };
  }
}

export {
  Decrypter,
  decrypt
};
