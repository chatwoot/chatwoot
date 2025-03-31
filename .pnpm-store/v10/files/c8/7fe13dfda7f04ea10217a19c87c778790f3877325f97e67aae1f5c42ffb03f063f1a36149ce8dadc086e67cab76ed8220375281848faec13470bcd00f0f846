import window from 'global/window'; // const log2 = Math.log2 ? Math.log2 : (x) => (Math.log(x) / Math.log(2));

var repeat = function repeat(str, len) {
  var acc = '';

  while (len--) {
    acc += str;
  }

  return acc;
}; // count the number of bits it would take to represent a number
// we used to do this with log2 but BigInt does not support builtin math
// Math.ceil(log2(x));


export var countBits = function countBits(x) {
  return x.toString(2).length;
}; // count the number of whole bytes it would take to represent a number

export var countBytes = function countBytes(x) {
  return Math.ceil(countBits(x) / 8);
};
export var padStart = function padStart(b, len, str) {
  if (str === void 0) {
    str = ' ';
  }

  return (repeat(str, len) + b.toString()).slice(-len);
};
export var isTypedArray = function isTypedArray(obj) {
  return ArrayBuffer.isView(obj);
};
export var toUint8 = function toUint8(bytes) {
  if (bytes instanceof Uint8Array) {
    return bytes;
  }

  if (!Array.isArray(bytes) && !isTypedArray(bytes) && !(bytes instanceof ArrayBuffer)) {
    // any non-number or NaN leads to empty uint8array
    // eslint-disable-next-line
    if (typeof bytes !== 'number' || typeof bytes === 'number' && bytes !== bytes) {
      bytes = 0;
    } else {
      bytes = [bytes];
    }
  }

  return new Uint8Array(bytes && bytes.buffer || bytes, bytes && bytes.byteOffset || 0, bytes && bytes.byteLength || 0);
};
export var toHexString = function toHexString(bytes) {
  bytes = toUint8(bytes);
  var str = '';

  for (var i = 0; i < bytes.length; i++) {
    str += padStart(bytes[i].toString(16), 2, '0');
  }

  return str;
};
export var toBinaryString = function toBinaryString(bytes) {
  bytes = toUint8(bytes);
  var str = '';

  for (var i = 0; i < bytes.length; i++) {
    str += padStart(bytes[i].toString(2), 8, '0');
  }

  return str;
};
var BigInt = window.BigInt || Number;
var BYTE_TABLE = [BigInt('0x1'), BigInt('0x100'), BigInt('0x10000'), BigInt('0x1000000'), BigInt('0x100000000'), BigInt('0x10000000000'), BigInt('0x1000000000000'), BigInt('0x100000000000000'), BigInt('0x10000000000000000')];
export var ENDIANNESS = function () {
  var a = new Uint16Array([0xFFCC]);
  var b = new Uint8Array(a.buffer, a.byteOffset, a.byteLength);

  if (b[0] === 0xFF) {
    return 'big';
  }

  if (b[0] === 0xCC) {
    return 'little';
  }

  return 'unknown';
}();
export var IS_BIG_ENDIAN = ENDIANNESS === 'big';
export var IS_LITTLE_ENDIAN = ENDIANNESS === 'little';
export var bytesToNumber = function bytesToNumber(bytes, _temp) {
  var _ref = _temp === void 0 ? {} : _temp,
      _ref$signed = _ref.signed,
      signed = _ref$signed === void 0 ? false : _ref$signed,
      _ref$le = _ref.le,
      le = _ref$le === void 0 ? false : _ref$le;

  bytes = toUint8(bytes);
  var fn = le ? 'reduce' : 'reduceRight';
  var obj = bytes[fn] ? bytes[fn] : Array.prototype[fn];
  var number = obj.call(bytes, function (total, byte, i) {
    var exponent = le ? i : Math.abs(i + 1 - bytes.length);
    return total + BigInt(byte) * BYTE_TABLE[exponent];
  }, BigInt(0));

  if (signed) {
    var max = BYTE_TABLE[bytes.length] / BigInt(2) - BigInt(1);
    number = BigInt(number);

    if (number > max) {
      number -= max;
      number -= max;
      number -= BigInt(2);
    }
  }

  return Number(number);
};
export var numberToBytes = function numberToBytes(number, _temp2) {
  var _ref2 = _temp2 === void 0 ? {} : _temp2,
      _ref2$le = _ref2.le,
      le = _ref2$le === void 0 ? false : _ref2$le;

  // eslint-disable-next-line
  if (typeof number !== 'bigint' && typeof number !== 'number' || typeof number === 'number' && number !== number) {
    number = 0;
  }

  number = BigInt(number);
  var byteCount = countBytes(number);
  var bytes = new Uint8Array(new ArrayBuffer(byteCount));

  for (var i = 0; i < byteCount; i++) {
    var byteIndex = le ? i : Math.abs(i + 1 - bytes.length);
    bytes[byteIndex] = Number(number / BYTE_TABLE[i] & BigInt(0xFF));

    if (number < 0) {
      bytes[byteIndex] = Math.abs(~bytes[byteIndex]);
      bytes[byteIndex] -= i === 0 ? 1 : 2;
    }
  }

  return bytes;
};
export var bytesToString = function bytesToString(bytes) {
  if (!bytes) {
    return '';
  } // TODO: should toUint8 handle cases where we only have 8 bytes
  // but report more since this is a Uint16+ Array?


  bytes = Array.prototype.slice.call(bytes);
  var string = String.fromCharCode.apply(null, toUint8(bytes));

  try {
    return decodeURIComponent(escape(string));
  } catch (e) {// if decodeURIComponent/escape fails, we are dealing with partial
    // or full non string data. Just return the potentially garbled string.
  }

  return string;
};
export var stringToBytes = function stringToBytes(string, stringIsBytes) {
  if (typeof string !== 'string' && string && typeof string.toString === 'function') {
    string = string.toString();
  }

  if (typeof string !== 'string') {
    return new Uint8Array();
  } // If the string already is bytes, we don't have to do this
  // otherwise we do this so that we split multi length characters
  // into individual bytes


  if (!stringIsBytes) {
    string = unescape(encodeURIComponent(string));
  }

  var view = new Uint8Array(string.length);

  for (var i = 0; i < string.length; i++) {
    view[i] = string.charCodeAt(i);
  }

  return view;
};
export var concatTypedArrays = function concatTypedArrays() {
  for (var _len = arguments.length, buffers = new Array(_len), _key = 0; _key < _len; _key++) {
    buffers[_key] = arguments[_key];
  }

  buffers = buffers.filter(function (b) {
    return b && (b.byteLength || b.length) && typeof b !== 'string';
  });

  if (buffers.length <= 1) {
    // for 0 length we will return empty uint8
    // for 1 length we return the first uint8
    return toUint8(buffers[0]);
  }

  var totalLen = buffers.reduce(function (total, buf, i) {
    return total + (buf.byteLength || buf.length);
  }, 0);
  var tempBuffer = new Uint8Array(totalLen);
  var offset = 0;
  buffers.forEach(function (buf) {
    buf = toUint8(buf);
    tempBuffer.set(buf, offset);
    offset += buf.byteLength;
  });
  return tempBuffer;
};
/**
 * Check if the bytes "b" are contained within bytes "a".
 *
 * @param {Uint8Array|Array} a
 *        Bytes to check in
 *
 * @param {Uint8Array|Array} b
 *        Bytes to check for
 *
 * @param {Object} options
 *        options
 *
 * @param {Array|Uint8Array} [offset=0]
 *        offset to use when looking at bytes in a
 *
 * @param {Array|Uint8Array} [mask=[]]
 *        mask to use on bytes before comparison.
 *
 * @return {boolean}
 *         If all bytes in b are inside of a, taking into account
 *         bit masks.
 */

export var bytesMatch = function bytesMatch(a, b, _temp3) {
  var _ref3 = _temp3 === void 0 ? {} : _temp3,
      _ref3$offset = _ref3.offset,
      offset = _ref3$offset === void 0 ? 0 : _ref3$offset,
      _ref3$mask = _ref3.mask,
      mask = _ref3$mask === void 0 ? [] : _ref3$mask;

  a = toUint8(a);
  b = toUint8(b); // ie 11 does not support uint8 every

  var fn = b.every ? b.every : Array.prototype.every;
  return b.length && a.length - offset >= b.length && // ie 11 doesn't support every on uin8
  fn.call(b, function (bByte, i) {
    var aByte = mask[i] ? mask[i] & a[offset + i] : a[offset + i];
    return bByte === aByte;
  });
};
export var sliceBytes = function sliceBytes(src, start, end) {
  if (Uint8Array.prototype.slice) {
    return Uint8Array.prototype.slice.call(src, start, end);
  }

  return new Uint8Array(Array.prototype.slice.call(src, start, end));
};
export var reverseBytes = function reverseBytes(src) {
  if (src.reverse) {
    return src.reverse();
  }

  return Array.prototype.reverse.call(src);
};