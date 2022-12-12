"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.parseData = exports.parseTracks = exports.decodeBlock = exports.findEbml = exports.EBML_TAGS = void 0;

var _byteHelpers = require("./byte-helpers");

var _codecHelpers = require("./codec-helpers.js");

// relevant specs for this parser:
// https://matroska-org.github.io/libebml/specs.html
// https://www.matroska.org/technical/elements.html
// https://www.webmproject.org/docs/container/
var EBML_TAGS = {
  EBML: (0, _byteHelpers.toUint8)([0x1A, 0x45, 0xDF, 0xA3]),
  DocType: (0, _byteHelpers.toUint8)([0x42, 0x82]),
  Segment: (0, _byteHelpers.toUint8)([0x18, 0x53, 0x80, 0x67]),
  SegmentInfo: (0, _byteHelpers.toUint8)([0x15, 0x49, 0xA9, 0x66]),
  Tracks: (0, _byteHelpers.toUint8)([0x16, 0x54, 0xAE, 0x6B]),
  Track: (0, _byteHelpers.toUint8)([0xAE]),
  TrackNumber: (0, _byteHelpers.toUint8)([0xd7]),
  DefaultDuration: (0, _byteHelpers.toUint8)([0x23, 0xe3, 0x83]),
  TrackEntry: (0, _byteHelpers.toUint8)([0xAE]),
  TrackType: (0, _byteHelpers.toUint8)([0x83]),
  FlagDefault: (0, _byteHelpers.toUint8)([0x88]),
  CodecID: (0, _byteHelpers.toUint8)([0x86]),
  CodecPrivate: (0, _byteHelpers.toUint8)([0x63, 0xA2]),
  VideoTrack: (0, _byteHelpers.toUint8)([0xe0]),
  AudioTrack: (0, _byteHelpers.toUint8)([0xe1]),
  // Not used yet, but will be used for live webm/mkv
  // see https://www.matroska.org/technical/basics.html#block-structure
  // see https://www.matroska.org/technical/basics.html#simpleblock-structure
  Cluster: (0, _byteHelpers.toUint8)([0x1F, 0x43, 0xB6, 0x75]),
  Timestamp: (0, _byteHelpers.toUint8)([0xE7]),
  TimestampScale: (0, _byteHelpers.toUint8)([0x2A, 0xD7, 0xB1]),
  BlockGroup: (0, _byteHelpers.toUint8)([0xA0]),
  BlockDuration: (0, _byteHelpers.toUint8)([0x9B]),
  Block: (0, _byteHelpers.toUint8)([0xA1]),
  SimpleBlock: (0, _byteHelpers.toUint8)([0xA3])
};
/**
 * This is a simple table to determine the length
 * of things in ebml. The length is one based (starts at 1,
 * rather than zero) and for every zero bit before a one bit
 * we add one to length. We also need this table because in some
 * case we have to xor all the length bits from another value.
 */

exports.EBML_TAGS = EBML_TAGS;
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
    value: (0, _byteHelpers.bytesToNumber)(valueBytes, {
      signed: signed
    }),
    bytes: valueBytes
  };
};

var normalizePath = function normalizePath(path) {
  if (typeof path === 'string') {
    return path.match(/.{1,2}/g).map(function (p) {
      return normalizePath(p);
    });
  }

  if (typeof path === 'number') {
    return (0, _byteHelpers.numberToBytes)(path);
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

var getInfinityDataSize = function getInfinityDataSize(id, bytes, offset) {
  if (offset >= bytes.length) {
    return bytes.length;
  }

  var innerid = getvint(bytes, offset, false);

  if ((0, _byteHelpers.bytesMatch)(id.bytes, innerid.bytes)) {
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
  paths = normalizePaths(paths);
  bytes = (0, _byteHelpers.toUint8)(bytes);
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

    if ((0, _byteHelpers.bytesMatch)(paths[0], id.bytes)) {
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


exports.findEbml = findEbml;

var decodeBlock = function decodeBlock(block, type, timestampScale, clusterTimestamp) {
  var duration;

  if (type === 'group') {
    duration = findEbml(block, [EBML_TAGS.BlockDuration])[0];

    if (duration) {
      duration = (0, _byteHelpers.bytesToNumber)(duration);
      duration = 1 / timestampScale * duration * timestampScale / 1000;
    }

    block = findEbml(block, [EBML_TAGS.Block])[0];
    type = 'block'; // treat data as a block after this point
  }

  var dv = new DataView(block.buffer, block.byteOffset, block.byteLength);
  var trackNumber = getvint(block, 0);
  var timestamp = dv.getInt16(trackNumber.length, false);
  var flags = block[trackNumber.length + 2];
  var data = block.subarray(trackNumber.length + 3); // pts/dts in seconds

  var ptsdts = 1 / timestampScale * (clusterTimestamp + timestamp) * timestampScale / 1000; // return the frame

  var parsed = {
    duration: duration,
    trackNumber: trackNumber.value,
    keyframe: type === 'simple' && flags >> 7 === 1,
    invisible: (flags & 0x08) >> 3 === 1,
    lacing: (flags & 0x06) >> 1,
    discardable: type === 'simple' && (flags & 0x01) === 1,
    frames: [],
    pts: ptsdts,
    dts: ptsdts,
    timestamp: timestamp
  };

  if (!parsed.lacing) {
    parsed.frames.push(data);
    return parsed;
  }

  var numberOfFrames = data[0] + 1;
  var frameSizes = [];
  var offset = 1; // Fixed

  if (parsed.lacing === 2) {
    var sizeOfFrame = (data.length - offset) / numberOfFrames;

    for (var i = 0; i < numberOfFrames; i++) {
      frameSizes.push(sizeOfFrame);
    }
  } // xiph


  if (parsed.lacing === 1) {
    for (var _i = 0; _i < numberOfFrames - 1; _i++) {
      var size = 0;

      do {
        size += data[offset];
        offset++;
      } while (data[offset - 1] === 0xFF);

      frameSizes.push(size);
    }
  } // ebml


  if (parsed.lacing === 3) {
    // first vint is unsinged
    // after that vints are singed and
    // based on a compounding size
    var _size = 0;

    for (var _i2 = 0; _i2 < numberOfFrames - 1; _i2++) {
      var vint = _i2 === 0 ? getvint(data, offset) : getvint(data, offset, true, true);
      _size += vint.value;
      frameSizes.push(_size);
      offset += vint.length;
    }
  }

  frameSizes.forEach(function (size) {
    parsed.frames.push(data.subarray(offset, offset + size));
    offset += size;
  });
  return parsed;
}; // VP9 Codec Feature Metadata (CodecPrivate)
// https://www.webmproject.org/docs/container/


exports.decodeBlock = decodeBlock;

var parseVp9Private = function parseVp9Private(bytes) {
  var i = 0;
  var params = {};

  while (i < bytes.length) {
    var id = bytes[i] & 0x7f;
    var len = bytes[i + 1];
    var val = void 0;

    if (len === 1) {
      val = bytes[i + 2];
    } else {
      val = bytes.subarray(i + 2, i + 2 + len);
    }

    if (id === 1) {
      params.profile = val;
    } else if (id === 2) {
      params.level = val;
    } else if (id === 3) {
      params.bitDepth = val;
    } else if (id === 4) {
      params.chromaSubsampling = val;
    } else {
      params[id] = val;
    }

    i += 2 + len;
  }

  return params;
};

var parseTracks = function parseTracks(bytes) {
  bytes = (0, _byteHelpers.toUint8)(bytes);
  var decodedTracks = [];
  var tracks = findEbml(bytes, [EBML_TAGS.Segment, EBML_TAGS.Tracks, EBML_TAGS.Track]);

  if (!tracks.length) {
    tracks = findEbml(bytes, [EBML_TAGS.Tracks, EBML_TAGS.Track]);
  }

  if (!tracks.length) {
    tracks = findEbml(bytes, [EBML_TAGS.Track]);
  }

  if (!tracks.length) {
    return decodedTracks;
  }

  tracks.forEach(function (track) {
    var trackType = findEbml(track, EBML_TAGS.TrackType)[0];

    if (!trackType || !trackType.length) {
      return;
    } // 1 is video, 2 is audio, 17 is subtitle
    // other values are unimportant in this context


    if (trackType[0] === 1) {
      trackType = 'video';
    } else if (trackType[0] === 2) {
      trackType = 'audio';
    } else if (trackType[0] === 17) {
      trackType = 'subtitle';
    } else {
      return;
    } // todo parse language


    var decodedTrack = {
      rawCodec: (0, _byteHelpers.bytesToString)(findEbml(track, [EBML_TAGS.CodecID])[0]),
      type: trackType,
      codecPrivate: findEbml(track, [EBML_TAGS.CodecPrivate])[0],
      number: (0, _byteHelpers.bytesToNumber)(findEbml(track, [EBML_TAGS.TrackNumber])[0]),
      defaultDuration: (0, _byteHelpers.bytesToNumber)(findEbml(track, [EBML_TAGS.DefaultDuration])[0]),
      default: findEbml(track, [EBML_TAGS.FlagDefault])[0],
      rawData: track
    };
    var codec = '';

    if (/V_MPEG4\/ISO\/AVC/.test(decodedTrack.rawCodec)) {
      codec = "avc1." + (0, _codecHelpers.getAvcCodec)(decodedTrack.codecPrivate);
    } else if (/V_MPEGH\/ISO\/HEVC/.test(decodedTrack.rawCodec)) {
      codec = "hev1." + (0, _codecHelpers.getHvcCodec)(decodedTrack.codecPrivate);
    } else if (/V_MPEG4\/ISO\/ASP/.test(decodedTrack.rawCodec)) {
      if (decodedTrack.codecPrivate) {
        codec = 'mp4v.20.' + decodedTrack.codecPrivate[4].toString();
      } else {
        codec = 'mp4v.20.9';
      }
    } else if (/^V_THEORA/.test(decodedTrack.rawCodec)) {
      codec = 'theora';
    } else if (/^V_VP8/.test(decodedTrack.rawCodec)) {
      codec = 'vp8';
    } else if (/^V_VP9/.test(decodedTrack.rawCodec)) {
      if (decodedTrack.codecPrivate) {
        var _parseVp9Private = parseVp9Private(decodedTrack.codecPrivate),
            profile = _parseVp9Private.profile,
            level = _parseVp9Private.level,
            bitDepth = _parseVp9Private.bitDepth,
            chromaSubsampling = _parseVp9Private.chromaSubsampling;

        codec = 'vp09.';
        codec += (0, _byteHelpers.padStart)(profile, 2, '0') + ".";
        codec += (0, _byteHelpers.padStart)(level, 2, '0') + ".";
        codec += (0, _byteHelpers.padStart)(bitDepth, 2, '0') + ".";
        codec += "" + (0, _byteHelpers.padStart)(chromaSubsampling, 2, '0'); // Video -> Colour -> Ebml name

        var matrixCoefficients = findEbml(track, [0xE0, [0x55, 0xB0], [0x55, 0xB1]])[0] || [];
        var videoFullRangeFlag = findEbml(track, [0xE0, [0x55, 0xB0], [0x55, 0xB9]])[0] || [];
        var transferCharacteristics = findEbml(track, [0xE0, [0x55, 0xB0], [0x55, 0xBA]])[0] || [];
        var colourPrimaries = findEbml(track, [0xE0, [0x55, 0xB0], [0x55, 0xBB]])[0] || []; // if we find any optional codec parameter specify them all.

        if (matrixCoefficients.length || videoFullRangeFlag.length || transferCharacteristics.length || colourPrimaries.length) {
          codec += "." + (0, _byteHelpers.padStart)(colourPrimaries[0], 2, '0');
          codec += "." + (0, _byteHelpers.padStart)(transferCharacteristics[0], 2, '0');
          codec += "." + (0, _byteHelpers.padStart)(matrixCoefficients[0], 2, '0');
          codec += "." + (0, _byteHelpers.padStart)(videoFullRangeFlag[0], 2, '0');
        }
      } else {
        codec = 'vp9';
      }
    } else if (/^V_AV1/.test(decodedTrack.rawCodec)) {
      codec = "av01." + (0, _codecHelpers.getAv1Codec)(decodedTrack.codecPrivate);
    } else if (/A_ALAC/.test(decodedTrack.rawCodec)) {
      codec = 'alac';
    } else if (/A_MPEG\/L2/.test(decodedTrack.rawCodec)) {
      codec = 'mp2';
    } else if (/A_MPEG\/L3/.test(decodedTrack.rawCodec)) {
      codec = 'mp3';
    } else if (/^A_AAC/.test(decodedTrack.rawCodec)) {
      if (decodedTrack.codecPrivate) {
        codec = 'mp4a.40.' + (decodedTrack.codecPrivate[0] >>> 3).toString();
      } else {
        codec = 'mp4a.40.2';
      }
    } else if (/^A_AC3/.test(decodedTrack.rawCodec)) {
      codec = 'ac-3';
    } else if (/^A_PCM/.test(decodedTrack.rawCodec)) {
      codec = 'pcm';
    } else if (/^A_MS\/ACM/.test(decodedTrack.rawCodec)) {
      codec = 'speex';
    } else if (/^A_EAC3/.test(decodedTrack.rawCodec)) {
      codec = 'ec-3';
    } else if (/^A_VORBIS/.test(decodedTrack.rawCodec)) {
      codec = 'vorbis';
    } else if (/^A_FLAC/.test(decodedTrack.rawCodec)) {
      codec = 'flac';
    } else if (/^A_OPUS/.test(decodedTrack.rawCodec)) {
      codec = 'opus';
    }

    decodedTrack.codec = codec;
    decodedTracks.push(decodedTrack);
  });
  return decodedTracks.sort(function (a, b) {
    return a.number - b.number;
  });
};

exports.parseTracks = parseTracks;

var parseData = function parseData(data, tracks) {
  var allBlocks = [];
  var segment = findEbml(data, [EBML_TAGS.Segment])[0];
  var timestampScale = findEbml(segment, [EBML_TAGS.SegmentInfo, EBML_TAGS.TimestampScale])[0]; // in nanoseconds, defaults to 1ms

  if (timestampScale && timestampScale.length) {
    timestampScale = (0, _byteHelpers.bytesToNumber)(timestampScale);
  } else {
    timestampScale = 1000000;
  }

  var clusters = findEbml(segment, [EBML_TAGS.Cluster]);

  if (!tracks) {
    tracks = parseTracks(segment);
  }

  clusters.forEach(function (cluster, ci) {
    var simpleBlocks = findEbml(cluster, [EBML_TAGS.SimpleBlock]).map(function (b) {
      return {
        type: 'simple',
        data: b
      };
    });
    var blockGroups = findEbml(cluster, [EBML_TAGS.BlockGroup]).map(function (b) {
      return {
        type: 'group',
        data: b
      };
    });
    var timestamp = findEbml(cluster, [EBML_TAGS.Timestamp])[0] || 0;

    if (timestamp && timestamp.length) {
      timestamp = (0, _byteHelpers.bytesToNumber)(timestamp);
    } // get all blocks then sort them into the correct order


    var blocks = simpleBlocks.concat(blockGroups).sort(function (a, b) {
      return a.data.byteOffset - b.data.byteOffset;
    });
    blocks.forEach(function (block, bi) {
      var decoded = decodeBlock(block.data, block.type, timestampScale, timestamp);
      allBlocks.push(decoded);
    });
  });
  return {
    tracks: tracks,
    blocks: allBlocks
  };
};

exports.parseData = parseData;