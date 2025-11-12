"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.isLikelyFmp4MediaSegment = exports.detectContainerForBytes = exports.isLikely = void 0;

var _byteHelpers = require("./byte-helpers.js");

var _mp4Helpers = require("./mp4-helpers.js");

var _ebmlHelpers = require("./ebml-helpers.js");

var _id3Helpers = require("./id3-helpers.js");

var _nalHelpers = require("./nal-helpers.js");

var CONSTANTS = {
  // "webm" string literal in hex
  'webm': (0, _byteHelpers.toUint8)([0x77, 0x65, 0x62, 0x6d]),
  // "matroska" string literal in hex
  'matroska': (0, _byteHelpers.toUint8)([0x6d, 0x61, 0x74, 0x72, 0x6f, 0x73, 0x6b, 0x61]),
  // "fLaC" string literal in hex
  'flac': (0, _byteHelpers.toUint8)([0x66, 0x4c, 0x61, 0x43]),
  // "OggS" string literal in hex
  'ogg': (0, _byteHelpers.toUint8)([0x4f, 0x67, 0x67, 0x53]),
  // ac-3 sync byte, also works for ec-3 as that is simply a codec
  // of ac-3
  'ac3': (0, _byteHelpers.toUint8)([0x0b, 0x77]),
  // "RIFF" string literal in hex used for wav and avi
  'riff': (0, _byteHelpers.toUint8)([0x52, 0x49, 0x46, 0x46]),
  // "AVI" string literal in hex
  'avi': (0, _byteHelpers.toUint8)([0x41, 0x56, 0x49]),
  // "WAVE" string literal in hex
  'wav': (0, _byteHelpers.toUint8)([0x57, 0x41, 0x56, 0x45]),
  // "ftyp3g" string literal in hex
  '3gp': (0, _byteHelpers.toUint8)([0x66, 0x74, 0x79, 0x70, 0x33, 0x67]),
  // "ftyp" string literal in hex
  'mp4': (0, _byteHelpers.toUint8)([0x66, 0x74, 0x79, 0x70]),
  // "styp" string literal in hex
  'fmp4': (0, _byteHelpers.toUint8)([0x73, 0x74, 0x79, 0x70]),
  // "ftypqt" string literal in hex
  'mov': (0, _byteHelpers.toUint8)([0x66, 0x74, 0x79, 0x70, 0x71, 0x74]),
  // moov string literal in hex
  'moov': (0, _byteHelpers.toUint8)([0x6D, 0x6F, 0x6F, 0x76]),
  // moof string literal in hex
  'moof': (0, _byteHelpers.toUint8)([0x6D, 0x6F, 0x6F, 0x66])
};
var _isLikely = {
  aac: function aac(bytes) {
    var offset = (0, _id3Helpers.getId3Offset)(bytes);
    return (0, _byteHelpers.bytesMatch)(bytes, [0xFF, 0x10], {
      offset: offset,
      mask: [0xFF, 0x16]
    });
  },
  mp3: function mp3(bytes) {
    var offset = (0, _id3Helpers.getId3Offset)(bytes);
    return (0, _byteHelpers.bytesMatch)(bytes, [0xFF, 0x02], {
      offset: offset,
      mask: [0xFF, 0x06]
    });
  },
  webm: function webm(bytes) {
    var docType = (0, _ebmlHelpers.findEbml)(bytes, [_ebmlHelpers.EBML_TAGS.EBML, _ebmlHelpers.EBML_TAGS.DocType])[0]; // check if DocType EBML tag is webm

    return (0, _byteHelpers.bytesMatch)(docType, CONSTANTS.webm);
  },
  mkv: function mkv(bytes) {
    var docType = (0, _ebmlHelpers.findEbml)(bytes, [_ebmlHelpers.EBML_TAGS.EBML, _ebmlHelpers.EBML_TAGS.DocType])[0]; // check if DocType EBML tag is matroska

    return (0, _byteHelpers.bytesMatch)(docType, CONSTANTS.matroska);
  },
  mp4: function mp4(bytes) {
    // if this file is another base media file format, it is not mp4
    if (_isLikely['3gp'](bytes) || _isLikely.mov(bytes)) {
      return false;
    } // if this file starts with a ftyp or styp box its mp4


    if ((0, _byteHelpers.bytesMatch)(bytes, CONSTANTS.mp4, {
      offset: 4
    }) || (0, _byteHelpers.bytesMatch)(bytes, CONSTANTS.fmp4, {
      offset: 4
    })) {
      return true;
    } // if this file starts with a moof/moov box its mp4


    if ((0, _byteHelpers.bytesMatch)(bytes, CONSTANTS.moof, {
      offset: 4
    }) || (0, _byteHelpers.bytesMatch)(bytes, CONSTANTS.moov, {
      offset: 4
    })) {
      return true;
    }
  },
  mov: function mov(bytes) {
    return (0, _byteHelpers.bytesMatch)(bytes, CONSTANTS.mov, {
      offset: 4
    });
  },
  '3gp': function gp(bytes) {
    return (0, _byteHelpers.bytesMatch)(bytes, CONSTANTS['3gp'], {
      offset: 4
    });
  },
  ac3: function ac3(bytes) {
    var offset = (0, _id3Helpers.getId3Offset)(bytes);
    return (0, _byteHelpers.bytesMatch)(bytes, CONSTANTS.ac3, {
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
    var offset = (0, _id3Helpers.getId3Offset)(bytes);
    return (0, _byteHelpers.bytesMatch)(bytes, CONSTANTS.flac, {
      offset: offset
    });
  },
  ogg: function ogg(bytes) {
    return (0, _byteHelpers.bytesMatch)(bytes, CONSTANTS.ogg);
  },
  avi: function avi(bytes) {
    return (0, _byteHelpers.bytesMatch)(bytes, CONSTANTS.riff) && (0, _byteHelpers.bytesMatch)(bytes, CONSTANTS.avi, {
      offset: 8
    });
  },
  wav: function wav(bytes) {
    return (0, _byteHelpers.bytesMatch)(bytes, CONSTANTS.riff) && (0, _byteHelpers.bytesMatch)(bytes, CONSTANTS.wav, {
      offset: 8
    });
  },
  'h264': function h264(bytes) {
    // find seq_parameter_set_rbsp
    return (0, _nalHelpers.findH264Nal)(bytes, 7, 3).length;
  },
  'h265': function h265(bytes) {
    // find video_parameter_set_rbsp or seq_parameter_set_rbsp
    return (0, _nalHelpers.findH265Nal)(bytes, [32, 33], 3).length;
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
    return isLikelyFn((0, _byteHelpers.toUint8)(bytes));
  };
}); // export after wrapping

var isLikely = _isLikely; // A useful list of file signatures can be found here
// https://en.wikipedia.org/wiki/List_of_file_signatures

exports.isLikely = isLikely;

var detectContainerForBytes = function detectContainerForBytes(bytes) {
  bytes = (0, _byteHelpers.toUint8)(bytes);

  for (var i = 0; i < isLikelyTypes.length; i++) {
    var type = isLikelyTypes[i];

    if (isLikely[type](bytes)) {
      return type;
    }
  }

  return '';
}; // fmp4 is not a container


exports.detectContainerForBytes = detectContainerForBytes;

var isLikelyFmp4MediaSegment = function isLikelyFmp4MediaSegment(bytes) {
  return (0, _mp4Helpers.findBox)(bytes, ['moof']).length > 0;
};

exports.isLikelyFmp4MediaSegment = isLikelyFmp4MediaSegment;