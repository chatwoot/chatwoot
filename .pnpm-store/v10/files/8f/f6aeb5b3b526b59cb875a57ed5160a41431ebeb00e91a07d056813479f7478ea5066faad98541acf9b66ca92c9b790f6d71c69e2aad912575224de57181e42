/**
 * mux.js
 *
 * Copyright (c) Brightcove
 * Licensed Apache-2.0 https://github.com/videojs/mux.js/blob/master/LICENSE
 */
'use strict';

var ExpGolomb;
/**
 * Parser for exponential Golomb codes, a variable-bitwidth number encoding
 * scheme used by h264.
 */

ExpGolomb = function ExpGolomb(workingData) {
  var // the number of bytes left to examine in workingData
  workingBytesAvailable = workingData.byteLength,
      // the current word being examined
  workingWord = 0,
      // :uint
  // the number of bits left to examine in the current word
  workingBitsAvailable = 0; // :uint;
  // ():uint

  this.length = function () {
    return 8 * workingBytesAvailable;
  }; // ():uint


  this.bitsAvailable = function () {
    return 8 * workingBytesAvailable + workingBitsAvailable;
  }; // ():void


  this.loadWord = function () {
    var position = workingData.byteLength - workingBytesAvailable,
        workingBytes = new Uint8Array(4),
        availableBytes = Math.min(4, workingBytesAvailable);

    if (availableBytes === 0) {
      throw new Error('no bytes available');
    }

    workingBytes.set(workingData.subarray(position, position + availableBytes));
    workingWord = new DataView(workingBytes.buffer).getUint32(0); // track the amount of workingData that has been processed

    workingBitsAvailable = availableBytes * 8;
    workingBytesAvailable -= availableBytes;
  }; // (count:int):void


  this.skipBits = function (count) {
    var skipBytes; // :int

    if (workingBitsAvailable > count) {
      workingWord <<= count;
      workingBitsAvailable -= count;
    } else {
      count -= workingBitsAvailable;
      skipBytes = Math.floor(count / 8);
      count -= skipBytes * 8;
      workingBytesAvailable -= skipBytes;
      this.loadWord();
      workingWord <<= count;
      workingBitsAvailable -= count;
    }
  }; // (size:int):uint


  this.readBits = function (size) {
    var bits = Math.min(workingBitsAvailable, size),
        // :uint
    valu = workingWord >>> 32 - bits; // :uint
    // if size > 31, handle error

    workingBitsAvailable -= bits;

    if (workingBitsAvailable > 0) {
      workingWord <<= bits;
    } else if (workingBytesAvailable > 0) {
      this.loadWord();
    }

    bits = size - bits;

    if (bits > 0) {
      return valu << bits | this.readBits(bits);
    }

    return valu;
  }; // ():uint


  this.skipLeadingZeros = function () {
    var leadingZeroCount; // :uint

    for (leadingZeroCount = 0; leadingZeroCount < workingBitsAvailable; ++leadingZeroCount) {
      if ((workingWord & 0x80000000 >>> leadingZeroCount) !== 0) {
        // the first bit of working word is 1
        workingWord <<= leadingZeroCount;
        workingBitsAvailable -= leadingZeroCount;
        return leadingZeroCount;
      }
    } // we exhausted workingWord and still have not found a 1


    this.loadWord();
    return leadingZeroCount + this.skipLeadingZeros();
  }; // ():void


  this.skipUnsignedExpGolomb = function () {
    this.skipBits(1 + this.skipLeadingZeros());
  }; // ():void


  this.skipExpGolomb = function () {
    this.skipBits(1 + this.skipLeadingZeros());
  }; // ():uint


  this.readUnsignedExpGolomb = function () {
    var clz = this.skipLeadingZeros(); // :uint

    return this.readBits(clz + 1) - 1;
  }; // ():int


  this.readExpGolomb = function () {
    var valu = this.readUnsignedExpGolomb(); // :int

    if (0x01 & valu) {
      // the number is odd if the low order bit is set
      return 1 + valu >>> 1; // add 1 to make it even, and divide by 2
    }

    return -1 * (valu >>> 1); // divide by two then make it negative
  }; // Some convenience functions
  // :Boolean


  this.readBoolean = function () {
    return this.readBits(1) === 1;
  }; // ():int


  this.readUnsignedByte = function () {
    return this.readBits(8);
  };

  this.loadWord();
};

module.exports = ExpGolomb;