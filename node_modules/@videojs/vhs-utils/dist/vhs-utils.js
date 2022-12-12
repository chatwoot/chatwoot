/*! @name @videojs/vhs-utils @version 3.0.5 @license MIT */
(function (global, factory) {
  typeof exports === 'object' && typeof module !== 'undefined' ? module.exports = factory() :
  typeof define === 'function' && define.amd ? define(factory) :
  (global = typeof globalThis !== 'undefined' ? globalThis : global || self, global.vhsUtils = factory());
}(this, (function () { 'use strict';

  var regexs = {
    // to determine mime types
    mp4: /^(av0?1|avc0?[1234]|vp0?9|flac|opus|mp3|mp4a|mp4v|stpp.ttml.im1t)/,
    webm: /^(vp0?[89]|av0?1|opus|vorbis)/,
    ogg: /^(vp0?[89]|theora|flac|opus|vorbis)/,
    // to determine if a codec is audio or video
    video: /^(av0?1|avc0?[1234]|vp0?[89]|hvc1|hev1|theora|mp4v)/,
    audio: /^(mp4a|flac|vorbis|opus|ac-[34]|ec-3|alac|mp3|speex|aac)/,
    text: /^(stpp.ttml.im1t)/,
    // mux.js support regex
    muxerVideo: /^(avc0?1)/,
    muxerAudio: /^(mp4a)/,
    // match nothing as muxer does not support text right now.
    // there cannot never be a character before the start of a string
    // so this matches nothing.
    muxerText: /a^/
  };
  var mediaTypes = ['video', 'audio', 'text'];
  var upperMediaTypes = ['Video', 'Audio', 'Text'];
  /**
   * Replace the old apple-style `avc1.<dd>.<dd>` codec string with the standard
   * `avc1.<hhhhhh>`
   *
   * @param {string} codec
   *        Codec string to translate
   * @return {string}
   *         The translated codec string
   */

  var translateLegacyCodec = function translateLegacyCodec(codec) {
    if (!codec) {
      return codec;
    }

    return codec.replace(/avc1\.(\d+)\.(\d+)/i, function (orig, profile, avcLevel) {
      var profileHex = ('00' + Number(profile).toString(16)).slice(-2);
      var avcLevelHex = ('00' + Number(avcLevel).toString(16)).slice(-2);
      return 'avc1.' + profileHex + '00' + avcLevelHex;
    });
  };
  /**
   * Replace the old apple-style `avc1.<dd>.<dd>` codec strings with the standard
   * `avc1.<hhhhhh>`
   *
   * @param {string[]} codecs
   *        An array of codec strings to translate
   * @return {string[]}
   *         The translated array of codec strings
   */

  var translateLegacyCodecs = function translateLegacyCodecs(codecs) {
    return codecs.map(translateLegacyCodec);
  };
  /**
   * Replace codecs in the codec string with the old apple-style `avc1.<dd>.<dd>` to the
   * standard `avc1.<hhhhhh>`.
   *
   * @param {string} codecString
   *        The codec string
   * @return {string}
   *         The codec string with old apple-style codecs replaced
   *
   * @private
   */

  var mapLegacyAvcCodecs = function mapLegacyAvcCodecs(codecString) {
    return codecString.replace(/avc1\.(\d+)\.(\d+)/i, function (match) {
      return translateLegacyCodecs([match])[0];
    });
  };
  /**
   * @typedef {Object} ParsedCodecInfo
   * @property {number} codecCount
   *           Number of codecs parsed
   * @property {string} [videoCodec]
   *           Parsed video codec (if found)
   * @property {string} [videoObjectTypeIndicator]
   *           Video object type indicator (if found)
   * @property {string|null} audioProfile
   *           Audio profile
   */

  /**
   * Parses a codec string to retrieve the number of codecs specified, the video codec and
   * object type indicator, and the audio profile.
   *
   * @param {string} [codecString]
   *        The codec string to parse
   * @return {ParsedCodecInfo}
   *         Parsed codec info
   */

  var parseCodecs = function parseCodecs(codecString) {
    if (codecString === void 0) {
      codecString = '';
    }

    var codecs = codecString.split(',');
    var result = [];
    codecs.forEach(function (codec) {
      codec = codec.trim();
      var codecType;
      mediaTypes.forEach(function (name) {
        var match = regexs[name].exec(codec.toLowerCase());

        if (!match || match.length <= 1) {
          return;
        }

        codecType = name; // maintain codec case

        var type = codec.substring(0, match[1].length);
        var details = codec.replace(type, '');
        result.push({
          type: type,
          details: details,
          mediaType: name
        });
      });

      if (!codecType) {
        result.push({
          type: codec,
          details: '',
          mediaType: 'unknown'
        });
      }
    });
    return result;
  };
  /**
   * Returns a ParsedCodecInfo object for the default alternate audio playlist if there is
   * a default alternate audio playlist for the provided audio group.
   *
   * @param {Object} master
   *        The master playlist
   * @param {string} audioGroupId
   *        ID of the audio group for which to find the default codec info
   * @return {ParsedCodecInfo}
   *         Parsed codec info
   */

  var codecsFromDefault = function codecsFromDefault(master, audioGroupId) {
    if (!master.mediaGroups.AUDIO || !audioGroupId) {
      return null;
    }

    var audioGroup = master.mediaGroups.AUDIO[audioGroupId];

    if (!audioGroup) {
      return null;
    }

    for (var name in audioGroup) {
      var audioType = audioGroup[name];

      if (audioType.default && audioType.playlists) {
        // codec should be the same for all playlists within the audio type
        return parseCodecs(audioType.playlists[0].attributes.CODECS);
      }
    }

    return null;
  };
  var isVideoCodec = function isVideoCodec(codec) {
    if (codec === void 0) {
      codec = '';
    }

    return regexs.video.test(codec.trim().toLowerCase());
  };
  var isAudioCodec = function isAudioCodec(codec) {
    if (codec === void 0) {
      codec = '';
    }

    return regexs.audio.test(codec.trim().toLowerCase());
  };
  var isTextCodec = function isTextCodec(codec) {
    if (codec === void 0) {
      codec = '';
    }

    return regexs.text.test(codec.trim().toLowerCase());
  };
  var getMimeForCodec = function getMimeForCodec(codecString) {
    if (!codecString || typeof codecString !== 'string') {
      return;
    }

    var codecs = codecString.toLowerCase().split(',').map(function (c) {
      return translateLegacyCodec(c.trim());
    }); // default to video type

    var type = 'video'; // only change to audio type if the only codec we have is
    // audio

    if (codecs.length === 1 && isAudioCodec(codecs[0])) {
      type = 'audio';
    } else if (codecs.length === 1 && isTextCodec(codecs[0])) {
      // text uses application/<container> for now
      type = 'application';
    } // default the container to mp4


    var container = 'mp4'; // every codec must be able to go into the container
    // for that container to be the correct one

    if (codecs.every(function (c) {
      return regexs.mp4.test(c);
    })) {
      container = 'mp4';
    } else if (codecs.every(function (c) {
      return regexs.webm.test(c);
    })) {
      container = 'webm';
    } else if (codecs.every(function (c) {
      return regexs.ogg.test(c);
    })) {
      container = 'ogg';
    }

    return type + "/" + container + ";codecs=\"" + codecString + "\"";
  };
  var browserSupportsCodec = function browserSupportsCodec(codecString) {
    if (codecString === void 0) {
      codecString = '';
    }

    return window.MediaSource && window.MediaSource.isTypeSupported && window.MediaSource.isTypeSupported(getMimeForCodec(codecString)) || false;
  };
  var muxerSupportsCodec = function muxerSupportsCodec(codecString) {
    if (codecString === void 0) {
      codecString = '';
    }

    return codecString.toLowerCase().split(',').every(function (codec) {
      codec = codec.trim(); // any match is supported.

      for (var i = 0; i < upperMediaTypes.length; i++) {
        var type = upperMediaTypes[i];

        if (regexs["muxer" + type].test(codec)) {
          return true;
        }
      }

      return false;
    });
  };
  var DEFAULT_AUDIO_CODEC = 'mp4a.40.2';
  var DEFAULT_VIDEO_CODEC = 'avc1.4d400d';

  var codecs = /*#__PURE__*/Object.freeze({
    __proto__: null,
    translateLegacyCodec: translateLegacyCodec,
    translateLegacyCodecs: translateLegacyCodecs,
    mapLegacyAvcCodecs: mapLegacyAvcCodecs,
    parseCodecs: parseCodecs,
    codecsFromDefault: codecsFromDefault,
    isVideoCodec: isVideoCodec,
    isAudioCodec: isAudioCodec,
    isTextCodec: isTextCodec,
    getMimeForCodec: getMimeForCodec,
    browserSupportsCodec: browserSupportsCodec,
    muxerSupportsCodec: muxerSupportsCodec,
    DEFAULT_AUDIO_CODEC: DEFAULT_AUDIO_CODEC,
    DEFAULT_VIDEO_CODEC: DEFAULT_VIDEO_CODEC
  });

  // const log2 = Math.log2 ? Math.log2 : (x) => (Math.log(x) / Math.log(2));
  var repeat = function repeat(str, len) {
    var acc = '';

    while (len--) {
      acc += str;
    }

    return acc;
  }; // count the number of bits it would take to represent a number
  // we used to do this with log2 but BigInt does not support builtin math
  // Math.ceil(log2(x));


  var countBits = function countBits(x) {
    return x.toString(2).length;
  }; // count the number of whole bytes it would take to represent a number

  var countBytes = function countBytes(x) {
    return Math.ceil(countBits(x) / 8);
  };
  var padStart = function padStart(b, len, str) {
    if (str === void 0) {
      str = ' ';
    }

    return (repeat(str, len) + b.toString()).slice(-len);
  };
  var isArrayBufferView = function isArrayBufferView(obj) {
    if (ArrayBuffer.isView === 'function') {
      return ArrayBuffer.isView(obj);
    }

    return obj && obj.buffer instanceof ArrayBuffer;
  };
  var isTypedArray = function isTypedArray(obj) {
    return isArrayBufferView(obj);
  };
  var toUint8 = function toUint8(bytes) {
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
  var toHexString = function toHexString(bytes) {
    bytes = toUint8(bytes);
    var str = '';

    for (var i = 0; i < bytes.length; i++) {
      str += padStart(bytes[i].toString(16), 2, '0');
    }

    return str;
  };
  var toBinaryString = function toBinaryString(bytes) {
    bytes = toUint8(bytes);
    var str = '';

    for (var i = 0; i < bytes.length; i++) {
      str += padStart(bytes[i].toString(2), 8, '0');
    }

    return str;
  };
  var BigInt = window.BigInt || Number;
  var BYTE_TABLE = [BigInt('0x1'), BigInt('0x100'), BigInt('0x10000'), BigInt('0x1000000'), BigInt('0x100000000'), BigInt('0x10000000000'), BigInt('0x1000000000000'), BigInt('0x100000000000000'), BigInt('0x10000000000000000')];
  var ENDIANNESS = function () {
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
  var IS_BIG_ENDIAN = ENDIANNESS === 'big';
  var IS_LITTLE_ENDIAN = ENDIANNESS === 'little';
  var bytesToNumber = function bytesToNumber(bytes, _temp) {
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
  var numberToBytes = function numberToBytes(number, _temp2) {
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
  var bytesToString = function bytesToString(bytes) {
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
  var stringToBytes = function stringToBytes(string, stringIsBytes) {
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
  var concatTypedArrays = function concatTypedArrays() {
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

  var bytesMatch = function bytesMatch(a, b, _temp3) {
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
  var sliceBytes = function sliceBytes(src, start, end) {
    if (Uint8Array.prototype.slice) {
      return Uint8Array.prototype.slice.call(src, start, end);
    }

    return new Uint8Array(Array.prototype.slice.call(src, start, end));
  };
  var reverseBytes = function reverseBytes(src) {
    if (src.reverse) {
      return src.reverse();
    }

    return Array.prototype.reverse.call(src);
  };

  var byteHelpers = /*#__PURE__*/Object.freeze({
    __proto__: null,
    countBits: countBits,
    countBytes: countBytes,
    padStart: padStart,
    isArrayBufferView: isArrayBufferView,
    isTypedArray: isTypedArray,
    toUint8: toUint8,
    toHexString: toHexString,
    toBinaryString: toBinaryString,
    ENDIANNESS: ENDIANNESS,
    IS_BIG_ENDIAN: IS_BIG_ENDIAN,
    IS_LITTLE_ENDIAN: IS_LITTLE_ENDIAN,
    bytesToNumber: bytesToNumber,
    numberToBytes: numberToBytes,
    bytesToString: bytesToString,
    stringToBytes: stringToBytes,
    concatTypedArrays: concatTypedArrays,
    bytesMatch: bytesMatch,
    sliceBytes: sliceBytes,
    reverseBytes: reverseBytes
  });

  var normalizePath = function normalizePath(path) {
    if (typeof path === 'string') {
      return stringToBytes(path);
    }

    if (typeof path === 'number') {
      return path;
    }

    return path;
  };

  var normalizePaths = function normalizePaths(paths) {
    if (!Array.isArray(paths)) {
      return [normalizePath(paths)];
    }

    return paths.map(function (p) {
      return normalizePath(p);
    });
  };
  /**
   * find any number of boxes by name given a path to it in an iso bmff
   * such as mp4.
   *
   * @param {TypedArray} bytes
   *        bytes for the iso bmff to search for boxes in
   *
   * @param {Uint8Array[]|string[]|string|Uint8Array} name
   *        An array of paths or a single path representing the name
   *        of boxes to search through in bytes. Paths may be
   *        uint8 (character codes) or strings.
   *
   * @param {boolean} [complete=false]
   *        Should we search only for complete boxes on the final path.
   *        This is very useful when you do not want to get back partial boxes
   *        in the case of streaming files.
   *
   * @return {Uint8Array[]}
   *         An array of the end paths that we found.
   */

  var findBox = function findBox(bytes, paths, complete) {
    if (complete === void 0) {
      complete = false;
    }

    paths = normalizePaths(paths);
    bytes = toUint8(bytes);
    var results = [];

    if (!paths.length) {
      // short-circuit the search for empty paths
      return results;
    }

    var i = 0;

    while (i < bytes.length) {
      var size = (bytes[i] << 24 | bytes[i + 1] << 16 | bytes[i + 2] << 8 | bytes[i + 3]) >>> 0;
      var type = bytes.subarray(i + 4, i + 8); // invalid box format.

      if (size === 0) {
        break;
      }

      var end = i + size;

      if (end > bytes.length) {
        // this box is bigger than the number of bytes we have
        // and complete is set, we cannot find any more boxes.
        if (complete) {
          break;
        }

        end = bytes.length;
      }

      var data = bytes.subarray(i + 8, end);

      if (bytesMatch(type, paths[0])) {
        if (paths.length === 1) {
          // this is the end of the path and we've found the box we were
          // looking for
          results.push(data);
        } else {
          // recursively search for the next box along the path
          results.push.apply(results, findBox(data, paths.slice(1), complete));
        }
      }

      i = end;
    } // we've finished searching all of bytes


    return results;
  };

  // https://matroska-org.github.io/libebml/specs.html
  // https://www.matroska.org/technical/elements.html
  // https://www.webmproject.org/docs/container/

  var EBML_TAGS = {
    EBML: toUint8([0x1A, 0x45, 0xDF, 0xA3]),
    DocType: toUint8([0x42, 0x82]),
    Segment: toUint8([0x18, 0x53, 0x80, 0x67]),
    SegmentInfo: toUint8([0x15, 0x49, 0xA9, 0x66]),
    Tracks: toUint8([0x16, 0x54, 0xAE, 0x6B]),
    Track: toUint8([0xAE]),
    TrackNumber: toUint8([0xd7]),
    DefaultDuration: toUint8([0x23, 0xe3, 0x83]),
    TrackEntry: toUint8([0xAE]),
    TrackType: toUint8([0x83]),
    FlagDefault: toUint8([0x88]),
    CodecID: toUint8([0x86]),
    CodecPrivate: toUint8([0x63, 0xA2]),
    VideoTrack: toUint8([0xe0]),
    AudioTrack: toUint8([0xe1]),
    // Not used yet, but will be used for live webm/mkv
    // see https://www.matroska.org/technical/basics.html#block-structure
    // see https://www.matroska.org/technical/basics.html#simpleblock-structure
    Cluster: toUint8([0x1F, 0x43, 0xB6, 0x75]),
    Timestamp: toUint8([0xE7]),
    TimestampScale: toUint8([0x2A, 0xD7, 0xB1]),
    BlockGroup: toUint8([0xA0]),
    BlockDuration: toUint8([0x9B]),
    Block: toUint8([0xA1]),
    SimpleBlock: toUint8([0xA3])
  };
  /**
   * This is a simple table to determine the length
   * of things in ebml. The length is one based (starts at 1,
   * rather than zero) and for every zero bit before a one bit
   * we add one to length. We also need this table because in some
   * case we have to xor all the length bits from another value.
   */

  var LENGTH_TABLE = [128, 64, 32, 16, 8, 4, 2, 1];

  var getLength = function getLength(byte) {
    var len = 1;

    for (var i = 0; i < LENGTH_TABLE.length; i++) {
      if (byte & LENGTH_TABLE[i]) {
        break;
      }

      len++;
    }

    return len;
  }; // length in ebml is stored in the first 4 to 8 bits
  // of the first byte. 4 for the id length and 8 for the
  // data size length. Length is measured by converting the number to binary
  // then 1 + the number of zeros before a 1 is encountered starting
  // from the left.


  var getvint = function getvint(bytes, offset, removeLength, signed) {
    if (removeLength === void 0) {
      removeLength = true;
    }

    if (signed === void 0) {
      signed = false;
    }

    var length = getLength(bytes[offset]);
    var valueBytes = bytes.subarray(offset, offset + length); // NOTE that we do **not** subarray here because we need to copy these bytes
    // as they will be modified below to remove the dataSizeLen bits and we do not
    // want to modify the original data. normally we could just call slice on
    // uint8array but ie 11 does not support that...

    if (removeLength) {
      valueBytes = Array.prototype.slice.call(bytes, offset, offset + length);
      valueBytes[0] ^= LENGTH_TABLE[length - 1];
    }

    return {
      length: length,
      value: bytesToNumber(valueBytes, {
        signed: signed
      }),
      bytes: valueBytes
    };
  };

  var normalizePath$1 = function normalizePath(path) {
    if (typeof path === 'string') {
      return path.match(/.{1,2}/g).map(function (p) {
        return normalizePath(p);
      });
    }

    if (typeof path === 'number') {
      return numberToBytes(path);
    }

    return path;
  };

  var normalizePaths$1 = function normalizePaths(paths) {
    if (!Array.isArray(paths)) {
      return [normalizePath$1(paths)];
    }

    return paths.map(function (p) {
      return normalizePath$1(p);
    });
  };

  var getInfinityDataSize = function getInfinityDataSize(id, bytes, offset) {
    if (offset >= bytes.length) {
      return bytes.length;
    }

    var innerid = getvint(bytes, offset, false);

    if (bytesMatch(id.bytes, innerid.bytes)) {
      return offset;
    }

    var dataHeader = getvint(bytes, offset + innerid.length);
    return getInfinityDataSize(id, bytes, offset + dataHeader.length + dataHeader.value + innerid.length);
  };
  /**
   * Notes on the EBLM format.
   *
   * EBLM uses "vints" tags. Every vint tag contains
   * two parts
   *
   * 1. The length from the first byte. You get this by
   *    converting the byte to binary and counting the zeros
   *    before a 1. Then you add 1 to that. Examples
   *    00011111 = length 4 because there are 3 zeros before a 1.
   *    00100000 = length 3 because there are 2 zeros before a 1.
   *    00000011 = length 7 because there are 6 zeros before a 1.
   *
   * 2. The bits used for length are removed from the first byte
   *    Then all the bytes are merged into a value. NOTE: this
   *    is not the case for id ebml tags as there id includes
   *    length bits.
   *
   */


  var findEbml = function findEbml(bytes, paths) {
    paths = normalizePaths$1(paths);
    bytes = toUint8(bytes);
    var results = [];

    if (!paths.length) {
      return results;
    }

    var i = 0;

    while (i < bytes.length) {
      var id = getvint(bytes, i, false);
      var dataHeader = getvint(bytes, i + id.length);
      var dataStart = i + id.length + dataHeader.length; // dataSize is unknown or this is a live stream

      if (dataHeader.value === 0x7f) {
        dataHeader.value = getInfinityDataSize(id, bytes, dataStart);

        if (dataHeader.value !== bytes.length) {
          dataHeader.value -= dataStart;
        }
      }

      var dataEnd = dataStart + dataHeader.value > bytes.length ? bytes.length : dataStart + dataHeader.value;
      var data = bytes.subarray(dataStart, dataEnd);

      if (bytesMatch(paths[0], id.bytes)) {
        if (paths.length === 1) {
          // this is the end of the paths and we've found the tag we were
          // looking for
          results.push(data);
        } else {
          // recursively search for the next tag inside of the data
          // of this one
          results = results.concat(findEbml(data, paths.slice(1)));
        }
      }

      var totalLength = id.length + dataHeader.length + data.length; // move past this tag entirely, we are not looking for it

      i += totalLength;
    }

    return results;
  }; // see https://www.matroska.org/technical/basics.html#block-structure

  var ID3 = toUint8([0x49, 0x44, 0x33]);
  var getId3Size = function getId3Size(bytes, offset) {
    if (offset === void 0) {
      offset = 0;
    }

    bytes = toUint8(bytes);
    var flags = bytes[offset + 5];
    var returnSize = bytes[offset + 6] << 21 | bytes[offset + 7] << 14 | bytes[offset + 8] << 7 | bytes[offset + 9];
    var footerPresent = (flags & 16) >> 4;

    if (footerPresent) {
      return returnSize + 20;
    }

    return returnSize + 10;
  };
  var getId3Offset = function getId3Offset(bytes, offset) {
    if (offset === void 0) {
      offset = 0;
    }

    bytes = toUint8(bytes);

    if (bytes.length - offset < 10 || !bytesMatch(bytes, ID3, {
      offset: offset
    })) {
      return offset;
    }

    offset += getId3Size(bytes, offset); // recursive check for id3 tags as some files
    // have multiple ID3 tag sections even though
    // they should not.

    return getId3Offset(bytes, offset);
  };

  var NAL_TYPE_ONE = toUint8([0x00, 0x00, 0x00, 0x01]);
  var NAL_TYPE_TWO = toUint8([0x00, 0x00, 0x01]);
  var EMULATION_PREVENTION = toUint8([0x00, 0x00, 0x03]);
  /**
   * Expunge any "Emulation Prevention" bytes from a "Raw Byte
   * Sequence Payload"
   *
   * @param data {Uint8Array} the bytes of a RBSP from a NAL
   * unit
   * @return {Uint8Array} the RBSP without any Emulation
   * Prevention Bytes
   */

  var discardEmulationPreventionBytes = function discardEmulationPreventionBytes(bytes) {
    var positions = [];
    var i = 1; // Find all `Emulation Prevention Bytes`

    while (i < bytes.length - 2) {
      if (bytesMatch(bytes.subarray(i, i + 3), EMULATION_PREVENTION)) {
        positions.push(i + 2);
        i++;
      }

      i++;
    } // If no Emulation Prevention Bytes were found just return the original
    // array


    if (positions.length === 0) {
      return bytes;
    } // Create a new array to hold the NAL unit data


    var newLength = bytes.length - positions.length;
    var newData = new Uint8Array(newLength);
    var sourceIndex = 0;

    for (i = 0; i < newLength; sourceIndex++, i++) {
      if (sourceIndex === positions[0]) {
        // Skip this byte
        sourceIndex++; // Remove this position index

        positions.shift();
      }

      newData[i] = bytes[sourceIndex];
    }

    return newData;
  };
  var findNal = function findNal(bytes, dataType, types, nalLimit) {
    if (nalLimit === void 0) {
      nalLimit = Infinity;
    }

    bytes = toUint8(bytes);
    types = [].concat(types);
    var i = 0;
    var nalStart;
    var nalsFound = 0; // keep searching until:
    // we reach the end of bytes
    // we reach the maximum number of nals they want to seach
    // NOTE: that we disregard nalLimit when we have found the start
    // of the nal we want so that we can find the end of the nal we want.

    while (i < bytes.length && (nalsFound < nalLimit || nalStart)) {
      var nalOffset = void 0;

      if (bytesMatch(bytes.subarray(i), NAL_TYPE_ONE)) {
        nalOffset = 4;
      } else if (bytesMatch(bytes.subarray(i), NAL_TYPE_TWO)) {
        nalOffset = 3;
      } // we are unsynced,
      // find the next nal unit


      if (!nalOffset) {
        i++;
        continue;
      }

      nalsFound++;

      if (nalStart) {
        return discardEmulationPreventionBytes(bytes.subarray(nalStart, i));
      }

      var nalType = void 0;

      if (dataType === 'h264') {
        nalType = bytes[i + nalOffset] & 0x1f;
      } else if (dataType === 'h265') {
        nalType = bytes[i + nalOffset] >> 1 & 0x3f;
      }

      if (types.indexOf(nalType) !== -1) {
        nalStart = i + nalOffset;
      } // nal header is 1 length for h264, and 2 for h265


      i += nalOffset + (dataType === 'h264' ? 1 : 2);
    }

    return bytes.subarray(0, 0);
  };
  var findH264Nal = function findH264Nal(bytes, type, nalLimit) {
    return findNal(bytes, 'h264', type, nalLimit);
  };
  var findH265Nal = function findH265Nal(bytes, type, nalLimit) {
    return findNal(bytes, 'h265', type, nalLimit);
  };

  var CONSTANTS = {
    // "webm" string literal in hex
    'webm': toUint8([0x77, 0x65, 0x62, 0x6d]),
    // "matroska" string literal in hex
    'matroska': toUint8([0x6d, 0x61, 0x74, 0x72, 0x6f, 0x73, 0x6b, 0x61]),
    // "fLaC" string literal in hex
    'flac': toUint8([0x66, 0x4c, 0x61, 0x43]),
    // "OggS" string literal in hex
    'ogg': toUint8([0x4f, 0x67, 0x67, 0x53]),
    // ac-3 sync byte, also works for ec-3 as that is simply a codec
    // of ac-3
    'ac3': toUint8([0x0b, 0x77]),
    // "RIFF" string literal in hex used for wav and avi
    'riff': toUint8([0x52, 0x49, 0x46, 0x46]),
    // "AVI" string literal in hex
    'avi': toUint8([0x41, 0x56, 0x49]),
    // "WAVE" string literal in hex
    'wav': toUint8([0x57, 0x41, 0x56, 0x45]),
    // "ftyp3g" string literal in hex
    '3gp': toUint8([0x66, 0x74, 0x79, 0x70, 0x33, 0x67]),
    // "ftyp" string literal in hex
    'mp4': toUint8([0x66, 0x74, 0x79, 0x70]),
    // "styp" string literal in hex
    'fmp4': toUint8([0x73, 0x74, 0x79, 0x70]),
    // "ftypqt" string literal in hex
    'mov': toUint8([0x66, 0x74, 0x79, 0x70, 0x71, 0x74]),
    // moov string literal in hex
    'moov': toUint8([0x6D, 0x6F, 0x6F, 0x76]),
    // moof string literal in hex
    'moof': toUint8([0x6D, 0x6F, 0x6F, 0x66])
  };
  var _isLikely = {
    aac: function aac(bytes) {
      var offset = getId3Offset(bytes);
      return bytesMatch(bytes, [0xFF, 0x10], {
        offset: offset,
        mask: [0xFF, 0x16]
      });
    },
    mp3: function mp3(bytes) {
      var offset = getId3Offset(bytes);
      return bytesMatch(bytes, [0xFF, 0x02], {
        offset: offset,
        mask: [0xFF, 0x06]
      });
    },
    webm: function webm(bytes) {
      var docType = findEbml(bytes, [EBML_TAGS.EBML, EBML_TAGS.DocType])[0]; // check if DocType EBML tag is webm

      return bytesMatch(docType, CONSTANTS.webm);
    },
    mkv: function mkv(bytes) {
      var docType = findEbml(bytes, [EBML_TAGS.EBML, EBML_TAGS.DocType])[0]; // check if DocType EBML tag is matroska

      return bytesMatch(docType, CONSTANTS.matroska);
    },
    mp4: function mp4(bytes) {
      // if this file is another base media file format, it is not mp4
      if (_isLikely['3gp'](bytes) || _isLikely.mov(bytes)) {
        return false;
      } // if this file starts with a ftyp or styp box its mp4


      if (bytesMatch(bytes, CONSTANTS.mp4, {
        offset: 4
      }) || bytesMatch(bytes, CONSTANTS.fmp4, {
        offset: 4
      })) {
        return true;
      } // if this file starts with a moof/moov box its mp4


      if (bytesMatch(bytes, CONSTANTS.moof, {
        offset: 4
      }) || bytesMatch(bytes, CONSTANTS.moov, {
        offset: 4
      })) {
        return true;
      }
    },
    mov: function mov(bytes) {
      return bytesMatch(bytes, CONSTANTS.mov, {
        offset: 4
      });
    },
    '3gp': function gp(bytes) {
      return bytesMatch(bytes, CONSTANTS['3gp'], {
        offset: 4
      });
    },
    ac3: function ac3(bytes) {
      var offset = getId3Offset(bytes);
      return bytesMatch(bytes, CONSTANTS.ac3, {
        offset: offset
      });
    },
    ts: function ts(bytes) {
      if (bytes.length < 189 && bytes.length >= 1) {
        return bytes[0] === 0x47;
      }

      var i = 0; // check the first 376 bytes for two matching sync bytes

      while (i + 188 < bytes.length && i < 188) {
        if (bytes[i] === 0x47 && bytes[i + 188] === 0x47) {
          return true;
        }

        i += 1;
      }

      return false;
    },
    flac: function flac(bytes) {
      var offset = getId3Offset(bytes);
      return bytesMatch(bytes, CONSTANTS.flac, {
        offset: offset
      });
    },
    ogg: function ogg(bytes) {
      return bytesMatch(bytes, CONSTANTS.ogg);
    },
    avi: function avi(bytes) {
      return bytesMatch(bytes, CONSTANTS.riff) && bytesMatch(bytes, CONSTANTS.avi, {
        offset: 8
      });
    },
    wav: function wav(bytes) {
      return bytesMatch(bytes, CONSTANTS.riff) && bytesMatch(bytes, CONSTANTS.wav, {
        offset: 8
      });
    },
    'h264': function h264(bytes) {
      // find seq_parameter_set_rbsp
      return findH264Nal(bytes, 7, 3).length;
    },
    'h265': function h265(bytes) {
      // find video_parameter_set_rbsp or seq_parameter_set_rbsp
      return findH265Nal(bytes, [32, 33], 3).length;
    }
  }; // get all the isLikely functions
  // but make sure 'ts' is above h264 and h265
  // but below everything else as it is the least specific

  var isLikelyTypes = Object.keys(_isLikely) // remove ts, h264, h265
  .filter(function (t) {
    return t !== 'ts' && t !== 'h264' && t !== 'h265';
  }) // add it back to the bottom
  .concat(['ts', 'h264', 'h265']); // make sure we are dealing with uint8 data.

  isLikelyTypes.forEach(function (type) {
    var isLikelyFn = _isLikely[type];

    _isLikely[type] = function (bytes) {
      return isLikelyFn(toUint8(bytes));
    };
  }); // export after wrapping

  var isLikely = _isLikely; // A useful list of file signatures can be found here
  // https://en.wikipedia.org/wiki/List_of_file_signatures

  var detectContainerForBytes = function detectContainerForBytes(bytes) {
    bytes = toUint8(bytes);

    for (var i = 0; i < isLikelyTypes.length; i++) {
      var type = isLikelyTypes[i];

      if (isLikely[type](bytes)) {
        return type;
      }
    }

    return '';
  }; // fmp4 is not a container

  var isLikelyFmp4MediaSegment = function isLikelyFmp4MediaSegment(bytes) {
    return findBox(bytes, ['moof']).length > 0;
  };

  var containers = /*#__PURE__*/Object.freeze({
    __proto__: null,
    isLikely: isLikely,
    detectContainerForBytes: detectContainerForBytes,
    isLikelyFmp4MediaSegment: isLikelyFmp4MediaSegment
  });

  var atob = function atob(s) {
    return window.atob ? window.atob(s) : Buffer.from(s, 'base64').toString('binary');
  };

  function decodeB64ToUint8Array(b64Text) {
    var decodedString = atob(b64Text);
    var array = new Uint8Array(decodedString.length);

    for (var i = 0; i < decodedString.length; i++) {
      array[i] = decodedString.charCodeAt(i);
    }

    return array;
  }

  /**
   * Loops through all supported media groups in master and calls the provided
   * callback for each group
   *
   * @param {Object} master
   *        The parsed master manifest object
   * @param {string[]} groups
   *        The media groups to call the callback for
   * @param {Function} callback
   *        Callback to call for each media group
   */
  var forEachMediaGroup = function forEachMediaGroup(master, groups, callback) {
    groups.forEach(function (mediaType) {
      for (var groupKey in master.mediaGroups[mediaType]) {
        for (var labelKey in master.mediaGroups[mediaType][groupKey]) {
          var mediaProperties = master.mediaGroups[mediaType][groupKey][labelKey];
          callback(mediaProperties, mediaType, groupKey, labelKey);
        }
      }
    });
  };

  var mediaGroups = /*#__PURE__*/Object.freeze({
    __proto__: null,
    forEachMediaGroup: forEachMediaGroup
  });

  function createCommonjsModule(fn, basedir, module) {
  	return module = {
  	  path: basedir,
  	  exports: {},
  	  require: function (path, base) {
        return commonjsRequire(path, (base === undefined || base === null) ? module.path : base);
      }
  	}, fn(module, module.exports), module.exports;
  }

  function commonjsRequire () {
  	throw new Error('Dynamic requires are not currently supported by @rollup/plugin-commonjs');
  }

  var urlToolkit = createCommonjsModule(function (module, exports) {
    // see https://tools.ietf.org/html/rfc1808
    (function (root) {
      var URL_REGEX = /^((?:[a-zA-Z0-9+\-.]+:)?)(\/\/[^\/?#]*)?((?:[^\/?#]*\/)*[^;?#]*)?(;[^?#]*)?(\?[^#]*)?(#.*)?$/;
      var FIRST_SEGMENT_REGEX = /^([^\/?#]*)(.*)$/;
      var SLASH_DOT_REGEX = /(?:\/|^)\.(?=\/)/g;
      var SLASH_DOT_DOT_REGEX = /(?:\/|^)\.\.\/(?!\.\.\/)[^\/]*(?=\/)/g;
      var URLToolkit = {
        // If opts.alwaysNormalize is true then the path will always be normalized even when it starts with / or //
        // E.g
        // With opts.alwaysNormalize = false (default, spec compliant)
        // http://a.com/b/cd + /e/f/../g => http://a.com/e/f/../g
        // With opts.alwaysNormalize = true (not spec compliant)
        // http://a.com/b/cd + /e/f/../g => http://a.com/e/g
        buildAbsoluteURL: function buildAbsoluteURL(baseURL, relativeURL, opts) {
          opts = opts || {}; // remove any remaining space and CRLF

          baseURL = baseURL.trim();
          relativeURL = relativeURL.trim();

          if (!relativeURL) {
            // 2a) If the embedded URL is entirely empty, it inherits the
            // entire base URL (i.e., is set equal to the base URL)
            // and we are done.
            if (!opts.alwaysNormalize) {
              return baseURL;
            }

            var basePartsForNormalise = URLToolkit.parseURL(baseURL);

            if (!basePartsForNormalise) {
              throw new Error('Error trying to parse base URL.');
            }

            basePartsForNormalise.path = URLToolkit.normalizePath(basePartsForNormalise.path);
            return URLToolkit.buildURLFromParts(basePartsForNormalise);
          }

          var relativeParts = URLToolkit.parseURL(relativeURL);

          if (!relativeParts) {
            throw new Error('Error trying to parse relative URL.');
          }

          if (relativeParts.scheme) {
            // 2b) If the embedded URL starts with a scheme name, it is
            // interpreted as an absolute URL and we are done.
            if (!opts.alwaysNormalize) {
              return relativeURL;
            }

            relativeParts.path = URLToolkit.normalizePath(relativeParts.path);
            return URLToolkit.buildURLFromParts(relativeParts);
          }

          var baseParts = URLToolkit.parseURL(baseURL);

          if (!baseParts) {
            throw new Error('Error trying to parse base URL.');
          }

          if (!baseParts.netLoc && baseParts.path && baseParts.path[0] !== '/') {
            // If netLoc missing and path doesn't start with '/', assume everthing before the first '/' is the netLoc
            // This causes 'example.com/a' to be handled as '//example.com/a' instead of '/example.com/a'
            var pathParts = FIRST_SEGMENT_REGEX.exec(baseParts.path);
            baseParts.netLoc = pathParts[1];
            baseParts.path = pathParts[2];
          }

          if (baseParts.netLoc && !baseParts.path) {
            baseParts.path = '/';
          }

          var builtParts = {
            // 2c) Otherwise, the embedded URL inherits the scheme of
            // the base URL.
            scheme: baseParts.scheme,
            netLoc: relativeParts.netLoc,
            path: null,
            params: relativeParts.params,
            query: relativeParts.query,
            fragment: relativeParts.fragment
          };

          if (!relativeParts.netLoc) {
            // 3) If the embedded URL's <net_loc> is non-empty, we skip to
            // Step 7.  Otherwise, the embedded URL inherits the <net_loc>
            // (if any) of the base URL.
            builtParts.netLoc = baseParts.netLoc; // 4) If the embedded URL path is preceded by a slash "/", the
            // path is not relative and we skip to Step 7.

            if (relativeParts.path[0] !== '/') {
              if (!relativeParts.path) {
                // 5) If the embedded URL path is empty (and not preceded by a
                // slash), then the embedded URL inherits the base URL path
                builtParts.path = baseParts.path; // 5a) if the embedded URL's <params> is non-empty, we skip to
                // step 7; otherwise, it inherits the <params> of the base
                // URL (if any) and

                if (!relativeParts.params) {
                  builtParts.params = baseParts.params; // 5b) if the embedded URL's <query> is non-empty, we skip to
                  // step 7; otherwise, it inherits the <query> of the base
                  // URL (if any) and we skip to step 7.

                  if (!relativeParts.query) {
                    builtParts.query = baseParts.query;
                  }
                }
              } else {
                // 6) The last segment of the base URL's path (anything
                // following the rightmost slash "/", or the entire path if no
                // slash is present) is removed and the embedded URL's path is
                // appended in its place.
                var baseURLPath = baseParts.path;
                var newPath = baseURLPath.substring(0, baseURLPath.lastIndexOf('/') + 1) + relativeParts.path;
                builtParts.path = URLToolkit.normalizePath(newPath);
              }
            }
          }

          if (builtParts.path === null) {
            builtParts.path = opts.alwaysNormalize ? URLToolkit.normalizePath(relativeParts.path) : relativeParts.path;
          }

          return URLToolkit.buildURLFromParts(builtParts);
        },
        parseURL: function parseURL(url) {
          var parts = URL_REGEX.exec(url);

          if (!parts) {
            return null;
          }

          return {
            scheme: parts[1] || '',
            netLoc: parts[2] || '',
            path: parts[3] || '',
            params: parts[4] || '',
            query: parts[5] || '',
            fragment: parts[6] || ''
          };
        },
        normalizePath: function normalizePath(path) {
          // The following operations are
          // then applied, in order, to the new path:
          // 6a) All occurrences of "./", where "." is a complete path
          // segment, are removed.
          // 6b) If the path ends with "." as a complete path segment,
          // that "." is removed.
          path = path.split('').reverse().join('').replace(SLASH_DOT_REGEX, ''); // 6c) All occurrences of "<segment>/../", where <segment> is a
          // complete path segment not equal to "..", are removed.
          // Removal of these path segments is performed iteratively,
          // removing the leftmost matching pattern on each iteration,
          // until no matching pattern remains.
          // 6d) If the path ends with "<segment>/..", where <segment> is a
          // complete path segment not equal to "..", that
          // "<segment>/.." is removed.

          while (path.length !== (path = path.replace(SLASH_DOT_DOT_REGEX, '')).length) {}

          return path.split('').reverse().join('');
        },
        buildURLFromParts: function buildURLFromParts(parts) {
          return parts.scheme + parts.netLoc + parts.path + parts.params + parts.query + parts.fragment;
        }
      };
      module.exports = URLToolkit;
    })();
  });

  var DEFAULT_LOCATION = 'http://example.com';

  var resolveUrl = function resolveUrl(baseUrl, relativeUrl) {
    // return early if we don't need to resolve
    if (/^[a-z]+:/i.test(relativeUrl)) {
      return relativeUrl;
    } // if baseUrl is a data URI, ignore it and resolve everything relative to window.location


    if (/^data:/.test(baseUrl)) {
      baseUrl = window.location && window.location.href || '';
    } // IE11 supports URL but not the URL constructor
    // feature detect the behavior we want


    var nativeURL = typeof window.URL === 'function';
    var protocolLess = /^\/\//.test(baseUrl); // remove location if window.location isn't available (i.e. we're in node)
    // and if baseUrl isn't an absolute url

    var removeLocation = !window.location && !/\/\//i.test(baseUrl); // if the base URL is relative then combine with the current location

    if (nativeURL) {
      baseUrl = new window.URL(baseUrl, window.location || DEFAULT_LOCATION);
    } else if (!/\/\//i.test(baseUrl)) {
      baseUrl = urlToolkit.buildAbsoluteURL(window.location && window.location.href || '', baseUrl);
    }

    if (nativeURL) {
      var newUrl = new URL(relativeUrl, baseUrl); // if we're a protocol-less url, remove the protocol
      // and if we're location-less, remove the location
      // otherwise, return the url unmodified

      if (removeLocation) {
        return newUrl.href.slice(DEFAULT_LOCATION.length);
      } else if (protocolLess) {
        return newUrl.href.slice(newUrl.protocol.length);
      }

      return newUrl.href;
    }

    return urlToolkit.buildAbsoluteURL(baseUrl, relativeUrl);
  };

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

  var index = {
    codecs: codecs,
    byteHelpers: byteHelpers,
    containers: containers,
    decodeB64ToUint8Array: decodeB64ToUint8Array,
    mediaGroups: mediaGroups,
    resolveUrl: resolveUrl,
    Stream: Stream
  };

  return index;

})));
